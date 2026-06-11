---
name: enrich-contact
description: Look up a single person's full professional profile in Explorium. Provide an email, a name plus company, a LinkedIn URL, or a known prospect_id. Returns title, seniority, department, work email, phone, company firmographics, and the linkable prospect_id for downstream workflows.
---

# Enrich Contact

Resolve one person to an Explorium prospect_id and return their full enriched profile in a single pass.

## Input

The user will supply one of:
- An email address (e.g. `jane@acme.com`)
- A full name plus a company name or domain (e.g. `Jane Smith at Acme Corp` or `Jane Smith @ acme.com`)
- A LinkedIn profile URL (e.g. `https://www.linkedin.com/in/janesmith`)
- A known Explorium `prospect_id`

Optional flags the user may pass:
- `--company-context` to add firmographics for the matched employer.

## Workflow

1. **Classify the identifier.** Look at the raw input and pick exactly one resolution path. Do not run multiple match strategies in parallel; pick the strongest signal first and only fall back if it returns no match.
   - Email present and well-formed (contains `@` and a TLD) -> path A.
   - LinkedIn URL (matches `linkedin.com/in/...`) -> path B.
   - A bare `prospect_id` (looks like an Explorium ID, not a name) -> path D, skip resolution.
   - Full name plus any company token -> path C.
   - Phone-only input -> stop and tell the user this surface is not supported (see Limitations); ask them for an email, name+company, or LinkedIn URL.

2. **Resolve to a prospect_id.**
   - **Path A (email):** call `match-prospects` with `email` set to the supplied address. Take the single returned `prospect_id`.
   - **Path B (LinkedIn URL):** call `match-prospects` with `linkedin` set to the full URL. Take the returned `prospect_id`.
   - **Path C (name + company):** if the user gave a company name rather than a domain, first call `match-business` with `name` to resolve to `company_domain` and `business_id`. Then call `match-prospects` with `full_name` and `company_domain` (and `business_id` if available) on a single prospect row.
   - **Path D (prospect_id given):** skip matching, use the id directly.

3. **Handle ambiguous matches.** `match-prospects` may return zero rows. If it does:
   - For path A, re-try `match-prospects` with the company domain portion of the email plus the local-part split into a `first_name` / `last_name` guess if a reasonable guess can be made; otherwise report no match. Identity fields (`full_name`, `first_name`, `last_name`, `email`, `linkedin`, `company_domain`) are inputs to `match-prospects`, not filters on `fetch-entities`.
   - For path C, re-try `match-prospects` with first+last and the resolved `business_id` (from `match-business`) instead of `full_name`. If that still returns zero, narrow the company first via `match-business` and pass the resulting `business_id` again. Do not attempt to filter `fetch-entities` by `full_name`, `first_name`, `last_name`, or `company_domain`; those are not valid filter fields.
   - Never silently pick the first row if there is more than one plausible match. Ask.

4. **Enrich the resolved prospect.** Open a session and create a fresh `--table-name` such as `contact_profile_fill_<short_uuid>` seeded with the resolved `prospect_id` (the `match-prospects` step writes it). Then call `enrich-prospects --session-id <id> --table-name contact_profile_fill_<short_uuid> --enrichments contacts profiles --contact-types email` (~2 credits per row (email-only) vs ~5 credits per row (email + phone)). The CLI internally batches 50, so a single id is trivially within limits. Switch to `--contact-types email phone` only when phone numbers are required.
   - Recent LinkedIn post content for an individual prospect is not available via enrich-prospects. If the user asks for post content, surface this limitation and offer `enrich-business --type linkedin-posts` for the prospect's employer instead.

5. **Optional company context.** If the user asked for `--company-context` and a `business_id` is known (from step 2 path C, or from the profile enrichment output), seed a companion table from the `match-business` step (e.g. `contact_profile_fill_company_<short_uuid>`) and call `enrich-business --session-id <id> --table-name contact_profile_fill_company_<short_uuid> --enrichments firmographics`. Pull headcount, revenue range, country, linkedin_category.

6. **Assemble the output.** Pull from the enrichment tables and render the profile card in the format below. Do not show empty fields; omit any row where the value is missing or null. Always surface the `prospect_id` so the user can reuse it in follow-on tools.

## Output Format

**[Full Name]** at [Company]

| Field | Value |
|-------|-------|
| Job Title | |
| Job Level | (display canonical: `cxo` -> `c-suite`, `vp` -> `vice president`) |
| Job Department | (fallback "Unattributed" when null) |
| Professional Email | |
| Email | |
| Phone | |
| LinkedIn URL | |
| Company | |
| Company Domain | |
| Company Industry | linkedin_category or naics_category |
| Company Size | headcount bucket |
| Company Revenue | revenue range bucket |
| Company Country | |
| Prospect ID | |
| Business ID | |

If multiple candidates were surfaced during resolution and the user has not yet picked one, render a `### Candidates` table instead of the profile card, with one row per candidate showing full_name, job_title, company_name, company_domain, prospect_id, and ask the user which to enrich.

## Limitations

- High-profile public execs (CEOs, founders, well-known executives) often have suppressed contact data. `contact_emails` may return only personal addresses (gmail, etc.) with `contact_professional_email_status: null`. The presence-of-professional_email reachability heuristic is unreliable for top-100 execs - recommend LinkedIn outreach instead of cold email for this tier.
- Phone-only lookup is not a supported match key. The user must provide email, name+company, LinkedIn URL, or a prospect_id.
- No native accuracy or confidence score is returned per prospect. Treat the presence of `professional_email` plus `phone_number` as the practical quality signal.
- No `last_updated` timestamp is exposed per contact field.
- Management level surfaces as `job_level` buckets and department as `job_department`; finer sub-department breakdown is not available.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in any By-Department breakdown rather than dropping them.
- Map raw `prospect_job_seniority_level` values to canonical filter values for display: `cxo` -> `c-suite`, `vp` -> `vice president`.
- Company size and revenue are bucketed (e.g. headcount range, revenue range), not exact numbers.
