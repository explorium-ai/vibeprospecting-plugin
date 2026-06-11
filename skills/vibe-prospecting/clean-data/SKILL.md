---
name: clean-data
description: Triage, standardize, and validate a CSV, Excel, or JSON list of companies or contacts before enrichment. Profile fill rate and cardinality, normalize company names and domains, validate emails and phones, tag invalid rows non-destructively. Run before match-business or match-prospects so you do not pay to enrich noreply, disposable, or empty rows.
---

# Clean Data

Per-row cleanup on a GTM list before any Explorium match or enrich call. Profile, standardize, validate. Never destructive: raw input is preserved, invalid rows are tagged with reason codes rather than deleted. Out of scope: deduplication and canonical entity resolution (that is what `match-business` and `match-prospects` are for).

## Input

`$ARGUMENTS` is a path to a CSV, Excel, or JSON file. Parse the user message for optional sub-inputs:

- Schema hints if column names are ambiguous: which column is company name, domain, email, phone, country.
- Entity type: companies, contacts, or both. Default: infer from columns.
- Whether to run an MX-record check on email domains (slower, requires DNS). Default: off.
- Whether to produce a match-ready subset for downstream `match-business` or `match-prospects`. Default: no.

Example phrasings:

- "Clean this leads CSV before I import it to HubSpot."
- "Normalize the company names and domains in /path/accounts.xlsx."
- "Validate the emails in this file and tag the bad rows."
- "Prep this list for match-prospects, only keep contactable corporate rows."
- "Why does my country column have 200 different spellings."

## Workflow

1. **Copy raw input.** Before any transform, copy the input to `./00_raw/<filename>` and never write back. All transforms write to numbered phase folders: `01_profiled/`, `02_standardized/`, `03_validated/`. This is non-negotiable: the single most common failure mode in cleanup work is destructive transforms with no path back.

2. **Profile (do not skip).** Use pandas inline to compute fill rate, cardinality, top values, length distribution, and format-pattern frequency for every column. Save the profile snapshot. Read it before deciding what to clean.

   ```python
   import pandas as pd
   df = pd.read_csv(input_path)
   profile = pd.DataFrame({
       "fill_rate_pct": (df.notna().mean() * 100).round(1),
       "cardinality": df.nunique(),
       "top_value": df.apply(lambda c: c.dropna().astype(str).mode().iloc[0] if c.dropna().size else None),
       "avg_len": df.apply(lambda c: c.dropna().astype(str).str.len().mean()),
   })
   ```

   Things to look for in the profile:
   - Country column with 200+ distinct values: standardization problem, not coverage. Build an ISO Alpha-2 lookup so downstream filters align with Explorium's `company_country_code` surface.
   - Phone column where <50% parse as E.164: you will need `phonenumbers` and a country hint.
   - Company name 99th-percentile length above 100 chars: someone pasted addresses. Quarantine these.
   - Free-email providers (gmail, yahoo, qq) in the top 5 of the email column: decide your policy now. Usually do not auto-link them to a corporate account.
   - Fields with under 10% fill: probably not worth normalizing.
   - Literal strings `"NA"`, `"N/A"`, `"None"`, `"null"`, `"-"`: collapse to real nulls before validating, or they mask failures.

3. **Standardize string fields.** Run standardization BEFORE validation: a valid email like ` JOHN@ACME.COM ` fails naive regex without trim+lowercase first. For every string column do Unicode NFKC, trim, collapse internal whitespace, strip leading and trailing punctuation, collapse the null-token strings above to real nulls. Then field-specific:

   - **Company name.** Strip legal suffixes (`Inc`, `LLC`, `Ltd`, `GmbH`, `S.A.`, `株式会社`, ...) at end of string only. Use `cleanco` if available. Keep BOTH raw and normalized columns: raw for display and legal, normalized for matching.
   - **Domain.** Strip protocol and `www`. Fold to the eTLD+1 via `tldextract` (Public Suffix List). Flag free-email providers and disposable domains separately.
   - **Person name.** Parse with `nameparser`: honorifics (Mr, Dr), generational suffixes (Jr, III), credentials (PhD, Esq), particles (van, de, al). Be conservative. If confidence is low, store the raw string with a low-confidence flag.
   - **Phone.** Format to E.164 with `phonenumbers` (libphonenumber port). Hint country from the country column when available. Detect line type if SMS routing matters.
   - **Country.** Map free-text country names to ISO Alpha-2 codes (`United States` to `US`, `UK` to `GB`, `Deutschland` to `DE`). This is the same shape `company_country_code` accepts in Explorium filters, so the cleaned column is reusable downstream.
   - **Address.** Use `libpostal` (`pypostal`) if installed. Country-aware parsing; postal codes vary wildly.

   Common mistake: overwriting the display column with the normalized version. Always keep raw alongside normalized.

4. **Validate field-by-field.** Per field, add a boolean `<field>_valid` and a `<field>_reason` text column when invalid. Tag invalid rows; never delete them. Deletion is irreversible and you may need the row for a re-validation pass.

   - **Emails:** RFC 5322 syntax via `email-validator`; role-address detection (`info@`, `sales@`, `noreply@`, `support@`, `hello@`, `admin@`, `webmaster@`); disposable-domain check against the `disposable-email-domains` list; free-provider flag (`gmail`, `yahoo`, `qq`, `outlook`, ...) (flag, do not reject); optional MX-record check via DNS (off by default).
   - **Phones:** parse + format via `phonenumbers`. Tag `invalid_too_short`, `invalid_country`, `invalid_format` as appropriate.
   - **Domains:** valid eTLD, no IP literals, optional MX check.
   - **Country codes:** valid ISO Alpha-2 after normalization.

5. **Optional handoff to Explorium for entity resolution.** This skill cleans rows in isolation; it cannot tell you that `Starbucks EMEA` and `Starbucks Corporation` point to the same company. That is what `match-business` and `match-prospects` are for. If the user wants the handoff, produce a match-ready subset:

   - `company_name_norm` + `domain_norm` to `match-business` (name + website; falls back to domain-only on a mismatch).
   - `email_norm` (only when corporate, not role / free-provider / disposable) to `match-prospects` (email fetcher).
   - `full_name_parsed` + `company_name_norm` to `match-prospects` (name + company fetcher).
   - `linkedin_url` (validated) to `match-prospects` (linkedin fetcher).

   Filter out tagged-invalid rows before the match call so you do not spend credits matching `noreply@example.com` or disposable addresses. The returned `business_id` and `prospect_id` become the join keys for any downstream `enrich-business` or `enrich-prospects` call.

## Output Format

### Profile Snapshot
Per column: `fill_rate_pct`, `cardinality`, `top_value`, `avg_len`. Show as a markdown table. After the cleanup phases, re-run the profile and show before vs after on the columns that were touched, so the user can see the cleanup did something.

### Standardization Map
Per normalized field: raw column name, normalized column name, 3 to 5 example transformations (`"  ACME, Inc. "` to `acme`, `"WWW.Acme.COM"` to `acme.com`, `"+1 (415) 555 1212"` to `+14155551212`).

### Validation Verdict
Per validated field: counts of valid, invalid, risky. For invalid rows: a frequency table of reason codes (e.g. `role_address: 42`, `disposable_domain: 18`, `invalid_syntax: 6`).

### Cleaned File
A single CSV at `./03_validated/<input_name>_clean.csv`:
- All original columns, untouched.
- `<field>_norm` columns for every normalized field.
- `<field>_valid` boolean columns.
- `<field>_reason` text columns, populated only when invalid.

### Match-Ready Subset (only if the user asked for the handoff)
A second CSV at `./04_match_ready/<input_name>_for_match.csv`:
- Only rows that passed validation on the fields each match path needs.
- Only the columns each match path accepts.
- Plus a one-line summary of which `match-business` or `match-prospects` path each row subset should route to (count by path).

## Limitations

- This skill does NOT deduplicate rows or resolve to canonical entities. Two normalized strings can still refer to the same real-world business. Use `match-business` and `match-prospects` for that step.
- Person-name parsing is best-effort. Non-Western order, hyphenated families, and missing separators are flagged with a low-confidence marker; the raw string is always preserved.
- The MX-record check requires DNS resolution and adds 50 to 200ms per unique domain. Off by default.
- Free-email providers (gmail, yahoo) are flagged but cannot be linked to a corporate identity from this skill alone. Pair with `match-prospects` (which can match on email + company) when needed.
- Holding-company and subsidiary pitfalls are out of scope (e.g. `meta.com` vs `instagram.com` vs `whatsapp.com`). Resolve these via `enrich-business --type company-hierarchies` after the match step.
- If the input file lacks a country column entirely, phone normalization defaults to a permissive parser and may mis-format short numbers. Provide a default country in the user message when possible.
