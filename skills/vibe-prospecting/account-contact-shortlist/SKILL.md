---
name: account-contact-shortlist
description: Build a ranked shortlist of contacts at a target company for prospecting, deal acceleration, or renewal/expansion plays. Provide a company name or domain and optionally a use case or seniority focus.
---

# Account Contact Shortlist
Pull the right people at a target account and rank them for outreach, with a use-case lens (new business, active deal, renewal) and a reachability check.

## Input
The user provides via `$ARGUMENTS`:
- A company name or domain (required).
- Optional use case: "prospecting" (default), "deal acceleration", or "renewal" / "expansion".
- Optional seniority focus: e.g. "C-level", "VP+", "Director+", or a specific function (sales, marketing, RevOps, security, finance).
- Optional size of the shortlist (default 25, max 100).

## Workflow

1. **Resolve the account.** Run `match-business` with the company name and (if given) domain. Capture `business_id`, `company_name`, `company_domain`. If multiple plausible matches return, surface the top 2-3 with `linkedin_category`, `company_size`, `headcount`, `company_country_code`, and HQ city, then ask the user to confirm before continuing.

2. **Anchor with firmographics.** Open a session for enrichment writes (capture `--session-id <id>` and use a `--table-name` such as `account_shortlist`). `match-business` returns only `business_id`; to get firmographics (company_name, headcount, revenue_range, industry, HQ), call `enrich-business --type firmographics --session-id <id> --table-name <match_business_table>` immediately after. Capture the new `table_name` returned in the response (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. This call captures industry (`linkedin_category` / `naics_category`), `company_size`, `headcount`, `company_revenue`, `revenue_range`, HQ, and `is_public_company`, which frames the output header.

3. **Translate the use case into a sourcing plan.** Map the user input to an explicit persona blueprint before any prospect fetch:
   - "prospecting" / default -> broad coverage of likely buying-committee roles across Sales, Marketing, RevOps, IT, and Product, weighted toward Director, VP, and C-level.
   - "deal acceleration" -> economic buyer plus technical evaluator plus procurement; bias toward C-level and VP in the relevant function, plus one Director-level champion candidate.
   - "renewal" / "expansion" -> existing-owner functions (the team that uses the product) plus an executive sponsor; include Manager and Director levels alongside VP+.
   If the user passed a seniority or function override, intersect it with the blueprint and note any roles dropped.

4. **Resolve any free-text role or industry tokens via autocomplete.** For each `job_title` term in the blueprint (for example "Chief Revenue Officer", "Head of RevOps", "Director of Demand Gen") call `autocomplete` on `job_title` and pick the matching canonical values. Do the same for `linkedin_category` or `naics_category` only if the user constrained the industry beyond the resolved account. Skip autocomplete for `job_level`, `job_department`, and `has_email`, which are enum-bare fields. Intersect `job_title` with `job_level` enum to tighten - the autocomplete-resolved values are not enforced as exact-match (a `job_title`-only filter for `Vice President of Engineering` returned 4 of 5 non-VP rows in live testing). Combine `job_title` with `job_level: {values: ["vice president"]}` for tight matches.

5. **Pull candidate prospects.** Scope to the resolved account by passing `--businesses-table-name <prior_business_table>` from the `match-business` step in step 1 (the prior table holds the resolved `business_id`). When the user names a ROLE not a person (e.g. "the CFO at Notion", "the engineering leader at X"), `match-prospects` with `full_name="CFO"` returns 0 silently - DO NOT use that path. Instead use `fetch-entities` (this step) with an autocomplete-resolved `job_title` filter plus a `job_level` filter to surface candidates. Call `fetch-entities prospects --session-id <id> --businesses-table-name <prior_business_table> --table-name account_shortlist` filtered by:
   - `job_title` enum from autocomplete values (when role terms were given).
   - `job_level` enum, e.g. `{values:["c-suite","vice president","director"], negate:false}` (built from the blueprint; common values include `c-suite`, `vice president`, `director`, `manager`, and the full enum is broader with 15 values total including `owner`, `founder`, `president`, `senior manager`, `board member`, `partner`, `advisor`, etc. Consult `fetch-entities --all-parameters` when the use case calls for finer seniority).
   - `job_department` enum aligned to the use case. Common values include `engineering`, `marketing`, `sales`, `it`, `operations`, `finance`. The full enum is broader (29 values total, including `c-suite`, `product`, `customer success`, `human resources`, `security`, etc.). Consult `fetch-entities --all-parameters` when in doubt.
   - `has_email: true` as a reachability proxy (there is no native contact data-quality sort, so this is the substitute filter).
   Page until you have the requested shortlist size, or the result set is exhausted. Note: `fetch-entities` preview is hard-capped at 5 rows regardless of `--number-of-results`. The full slice only materializes via `export-to-csv` (paid). For interactive use, treat the 5-row preview as a sanity sample, not as the ranked top-N - use `export-to-csv` when the user wants the full shortlist materialized. If `enrich-prospects-contacts` later yields fewer verified emails than the target, widen the filters (drop `job_level` to also include `director`, or relax `has_email: true`) and re-run with the `exclude_key` parameter to avoid pulling the same rows.

6. **Enrich the shortlist.** Take the top candidates (up to the requested count, default 25) and call `enrich-prospects contacts --session-id <id> --table-name account_shortlist --contact-types email` in batches of 50 (~2 credits per row (email-only) vs ~5 credits per row (email + phone)). This fills `email`, `professional_email`, and `linkedin_url`. Switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). For the top 10 also call `enrich-prospects profiles --session-id <id> --table-name account_shortlist` to pull tenure, prior roles, and seniority signals that feed the ranking rationale.

7. **Rank and group.** Score each contact on three axes and combine into a single rank:
   - Persona fit (does the title and department match the use-case blueprint, weighted by seniority).
   - Reachability (presence of `professional_email`, then `email`, then `phone_number`).
   - Tenure / stability from the profile enrichment (recent joiners get a small bump for prospecting, a penalty for renewal).
   Break ties by seniority (`job_level`).

## Output Format

### Target Account
One line: `<company_name> (<company_domain>) - <linkedin_category or naics_category>, <headcount> employees, <revenue_range>, HQ <city, country>, <"public" | "private">`.

### Use Case Frame
State the resolved use case and what the shortlist optimizes for:
- **Prospecting**: buying-committee coverage across the functions most likely to engage on a first conversation.
- **Deal Acceleration**: economic buyer, technical evaluator, procurement, and a Director-level champion for an in-flight opportunity.
- **Renewal / Expansion**: current product owners plus an executive sponsor to widen the relationship.
List any user-provided seniority or function overrides that narrowed the blueprint.

### Shortlist

| Rank | Full Name | Job Title | Job Level | Job Department | Professional Email | Phone | LinkedIn | Why On The List |
|------|-----------|-----------|-----------|----------------|--------------------|-------|----------|-----------------|
| 1 |  |  |  |  |  |  |  |  |
| 2 |  |  |  |  |  |  |  |  |

"Why On The List" is one short clause referencing the persona blueprint slot the contact filled (for example "VP-level economic buyer in Sales" or "Director-level RevOps champion"). Map raw `prospect_job_seniority_level` values to canonical filter values for display in the Job Level column: `cxo` -> `c-suite`, `vp` -> `vice president`. Show "Unattributed" in the Job Department column when `job_department` is null (common for cross-functional senior roles).

### Coverage Read
Group the shortlist to show how well the account is covered:
- **By Department**: counts per `job_department` (e.g. "Sales 9, Marketing 6, Engineering 4, Unattributed 3"). The "Unattributed" bucket captures cross-functional senior roles (Chief X Officer, President, Founder) where `job_department` is null. Other departments only appear if `fetch-entities --all-parameters` confirmed they exist in the live enum.
- **By Seniority**: counts per `job_level` (e.g. "C-Suite 4, Vice President 7, Director 10, Manager 4"). Use the canonical filter values (`c-suite`, `vice president`), not the raw data labels (`cxo`, `vp`).
- **Reachability**: count with `professional_email`, with `email` only, with `phone_number`, and with none.

Flag gaps where the use case expected a slot but no contact was found (for example "No procurement contact surfaced for deal acceleration").

### Engagement Priority
Pick the top 5 to contact first and give a one-line reason each, distinguishing entry points (Manager / Director with strong reachability) from decision makers (VP / CXO in the relevant function). Suggest a simple outreach order across these 5.

### Next Steps
- Run `enrich-business --session-id <id> --table-name <prior_business_table>` with `funding-and-acquisitions`, `challenges`, or `strategic-insights` to brief the opener with fresh account context.
- Run `fetch-prospects-events --session-id <id> --table-name account_shortlist` against the shortlist to catch recent role changes or new-hire signals before sending the first touch.
- Re-run this shortlist with a different use case to compare the buying committee against the in-flight deal team.

## Limitations
- There is no native contact data-quality sort, so `has_email: true` plus the presence of `professional_email` and `phone_number` after enrichment are used as reachability proxies.
- `company_size` and `revenue_range` are bucketed, not continuous, so very narrow size cutoffs are not possible.
- There is no sub-department job-function filter, so `job_department` plus `job_title` autocomplete is the finest available cut on function.
- `is_public_company` is the only company-type filter; private subsidiary vs independent private cannot be distinguished from filters alone.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in the By-Department breakdown rather than dropping them.
