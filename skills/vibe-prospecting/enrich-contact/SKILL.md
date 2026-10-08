---
name: enrich-contact
description: Look up a single person's full professional profile in Explorium. Provide an email, a name plus company, a LinkedIn URL, or a known prospect_id. Returns title, seniority, department, work email, phone, company firmographics, and the linkable prospect_id for downstream workflows.
---

# Enrich Contact

Resolve one person and return their full enriched profile in a single pass.

## Input

The user will supply one of:
- An email address (e.g. `jane@acme.com`)
- A full name plus a company name or domain (e.g. `Jane Smith at Acme Corp`)
- A LinkedIn profile URL
- A known Explorium `prospect_id`

Optional: a request for company context (firmographics on the matched employer).

## Workflow

1. **Classify the identifier.** Pick exactly one resolution path: do not fan out match strategies in parallel. Use the strongest signal first and fall back only if it returns no match.
   - Email present and well-formed: path A.
   - LinkedIn URL: path B.
   - Bare `prospect_id`: path D, skip resolution.
   - Full name plus a company token: path C.
   - Phone present and well-formed (no other identifier): **path E. Match by `phone_number`.** The API DOES accept phone-only matches — earlier guidance to refuse this path was incorrect. Warn the user that phone-only resolution is best-effort and may match a personal-line owner rather than a current professional identity; confirm before enriching. Common use case: SDRs reverse-looking-up an inbound caller.

2. **Resolve the prospect.**
   - Path A: match the prospect by email.
   - Path B: match the prospect by LinkedIn URL.
   - Path C: if the user gave a company name, first resolve the business to get its canonical domain and `business_id`, then match the prospect by full name plus that company domain or id.
   - Path D: use the supplied id directly.

3. **Handle ambiguity.** If matching returns zero rows:
   - For path A, retry by splitting the email local-part into a name guess plus the company domain — **BUT skip this retry entirely when** (a) the company domain itself fails to resolve via match-business (a fake domain makes the split-and-retry futile), or (b) the local-part is non-name-like: digits-only, role accounts (`info@`, `contact@`, `sales@`, `noreply@`), or random strings. Burning credits on a guess that can't possibly land is worse than admitting the email didn't resolve.
   - For path C, retry with first/last name and the resolved `business_id` from a company match.
   - For path E (phone-only), if no match returns, stop and report — there is no documented secondary fallback for phone.
   - If multiple plausible rows return, surface a candidates table and ask the user to pick. Never silently take the first row.

3.5. **Verify identity coherence before enriching.** A guessed LinkedIn URL or a name+company match at a large company can converge on a homonym (a "Tim Cook" who runs a Geek Food shop in London, not Apple's CEO) — and the "candidates table" rule in step 3 only fires when one match call returns multiple rows, not when sequential fallbacks land on a single wrong row. Before paying for enrichment, check:
   - If the user supplied a company token, confirm the candidate's `profile_company_name` OR `profile_company_website` matches it.
   - If you reached this row via a *guessed* LinkedIn URL (not user-supplied), require company agreement.
   - On mismatch, surface the row as a candidate and ASK the user before spending credits.
   - For high-profile public execs (founders, CEOs, well-known executives), offer the LinkedIn-outreach recommendation up front even before retrying — their contact data is often suppressed and a name+company retry may silently land on a homonym at a different employer.

4. **Enrich the prospect.** Pull contacts and profile on the resolved person. Default to email-only contacts (~2 credits/result, cheaper); upgrade to email plus phone (~5 credits/result, ~2.5× the email-only cost) only when the user explicitly needs phone numbers (e.g. SDR dialer flows). **State the cost delta to the user before upgrading.**
   - Recent LinkedIn post content for an individual is not available. If the user asks for post content, surface this gap and offer the employer's LinkedIn posts via business enrichment instead.

5. **Optional company context.** If the user asked for company context (or path C resolved a `business_id`), enrich firmographics on the employer and surface headcount, revenue range, country, and industry.

6. **Assemble the output.** Render the card below. Omit empty fields. Always surface the `prospect_id`.

## Output Format

**[Full Name]** at [Company]

| Field | Value |
|-------|-------|
| Job Title | |
| Job Level | display canonical (e.g. `c-suite`, `vice president`) |
| Job Department | fallback "Unattributed" when null |
| Professional Email / Personal Email / Phone | |
| LinkedIn URL | |
| Company / Domain / Industry | |
| Company Size / Revenue / Country | buckets |
| prospect_id / business_id | |

If multiple candidates surfaced during resolution and the user has not yet picked, render a `### Candidates` table instead, with one row per candidate (name, title, company, domain, prospect_id) and ask which to enrich.

## Limitations

- High-profile public execs (CEOs, founders, well-known executives) often have suppressed contact data. Professional email may be null or only a personal address. Recommend LinkedIn outreach instead of cold email for this tier.
- **Phone-only lookup IS supported but lower-confidence.** Earlier guidance to refuse phone-only matches was incorrect; the API accepts `phone_number` alone (path E in Workflow step 1). Expect a higher rate of stale or personal-line attribution than email or LinkedIn paths. Warn the user before enriching.
- **Identity coherence check (Workflow step 3.5) is mandatory before any enrichment.** Sequential fallback paths (name+company → guessed LinkedIn URL) can converge on a homonym at a different employer. If user supplied a company token, candidate `profile_company_name`/`profile_company_website` MUST match before enriching.
- **Phone enrichment is ~2.5× the cost of email-only** (~5 cr/result vs ~2 cr/result). Quote the cost delta to the user before upgrading to phone-on.
- **Email local-part fallback is skipped when the domain is unresolvable or the local-part is non-name-like** (digits, role accounts, random strings). See Workflow step 3.
- No per-prospect accuracy or confidence score. Treat the presence of a professional email plus phone as the practical quality signal.
- No `last_updated` timestamp per contact field. Level and department are coarse buckets; department is null for many cross-functional senior roles (Chief X Officer, President, Founder), group under "Unattributed".
- Company size and revenue are bucketed, not exact numbers.
