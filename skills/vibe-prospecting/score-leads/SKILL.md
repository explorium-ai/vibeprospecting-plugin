---
name: score-leads
description: Gather the data needed to tier leads or cold contacts (mixed prospect IDs, emails, LinkedIn URLs, or name+company rows) as Hot / Warm / Cold against a buyer persona and ICP. Resolves each lead, fetches person profile and contact data, pulls account firmographics and recent business events, and returns a per-lead evidence row plus the persona/ICP rule set so the calling model can apply scoring math. Triggers on phrases like "score these leads", "tier this list", "rank inbound", "prioritize my MQLs", "which lead should I call first", "who should I prioritize from this list", "pull fit data on these contacts".
---

# Score Leads
Gather verified person, account, and trigger evidence per lead so leads can be tiered Hot / Warm / Cold against a stated persona and ICP.

## Input
- **Leads (required):** list of prospect IDs, emails, LinkedIn URLs, or name+company rows. Mixed types allowed.
- **Buyer persona (required):** at minimum, target job titles or title keywords, `job_level` (common values: `c-suite`, `vice president`, `director`, `manager`; full enum also includes `owner`, `founder`, `president`, `senior manager`, `board member`, `partner`, `advisor`, etc., consult `fetch-entities --all-parameters` for the full 15-value list), `job_department` (common values include `engineering`, `marketing`, `sales`, `it`, `operations`, `finance`; the full enum is broader with 29 values total, including `c-suite`, `product`, `customer success`, `human resources`, `security`, etc., consult `fetch-entities --all-parameters` when in doubt), optional seniority caveats.
- **ICP (required):** at minimum, company_country_code or company_region_country_code, company_size buckets, optional company_revenue buckets, optional linkedin_category OR naics_category, optional company_tech_stack_tech, optional company_age range.
- **Source label per lead (optional):** e.g. demo_request, pricing_inquiry, free_trial, content_download, webinar_attended, cold_inbound. Passed through verbatim, not derived.
- **Tier thresholds (optional):** Hot and Warm cutoffs on the composite the caller computes. Cold is the remainder.
- **Trigger lookback (optional):** default 90 days for recent business events.

## Workflow

1. **Lock the persona and ICP rule set.** Restate the persona (titles, job_level, job_department) and the ICP filter shape exactly as it will be used. If linkedin_category or naics_category strings are supplied as free text, run `autocomplete` for `linkedin_category` or `naics_category` first and substitute the canonical values; do the same for `company_tech_stack_tech`, `job_title`, and `city_region` if any appear. Intersect `job_title` with `job_level` enum to tighten - the autocomplete-resolved values are not enforced as exact-match (a `job_title`-only filter for `Vice President of Engineering` returned 4 of 5 non-VP rows in live testing). Combine `job_title` with `job_level: {values: ["vice president"]}` for tight matches. linkedin_category and naics_category are mutually exclusive; pick one. company_country_code and company_region_country_code are mutually exclusive; pick one. Persona and ICP both echo back in the final output so the scoring math is auditable.

2. **Resolve each lead to a prospect_id.** Bucket every input row; never silently drop one.
   - Numeric/known prospect_id rows pass through.
   - Email rows go through `match-prospects` keyed by email. Email is a unique identifier; a no-match is a hard fail, not a fallback to name search. A typo'd email must not silently resolve to a different real person.
   - LinkedIn URL rows go through `match-prospects` keyed by linkedin_url.
   - Name+company rows go through `match-prospects` keyed by full_name plus company_name (or company_domain when present). `match-prospects` returns only a `prospect_id` (or null). It does not return a confidence score, candidate-count, or list of multiple candidates. A name+company match at a 10k+ employee company is therefore indistinguishable from a unique email match in the response. The "Verified (caveat) - multiple candidates returned" branch is not reachable; treat name+company matches as Verified-with-caveat by default.
   - Free-text rows like "Jane Doe at Acme" parse to the name+company path.
   - Persona-only rows (no name, e.g. "the CFO at Notion", "VP Eng at X"): `match-prospects` with `full_name="CFO"` returns 0 silently - DO NOT use that path. Instead call `fetch-entities` with `entity_type: prospects`, `--businesses-table-name <match_business_table>`, and an autocomplete-resolved `job_title` filter plus a `job_level` filter. Surface the returned candidates as Verified (caveat) for the user to pick from.
   - Tag each row: Auto-resolved, Verified (caveat), Ambiguous (pause), or Failed (no match). Never reroute Failed emails into name search.

3. **Fetch person evidence.** Group resolved prospect_ids into batches of 50 and call `enrich-prospects --session-id <sid> --table-name lead_fit_prospects --type contacts profiles --contact-types email` (contacts gives email, professional_email, has_email; profiles gives full_name, first_name, last_name, job_title, linkedin_url, plus job_level / job_department signals as available). Cost is ~2 credits per row (email-only) vs ~5 credits per row (email + phone). Switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). Prospect-side linkedin-posts is not available. If recent activity matters to the persona fit, pull `enrich-business --type linkedin-posts --session-id <sid> --table-name lead_fit_accounts` on the lead's employer instead. Stick to the 50-row batch ceiling.

4. **Resolve the lead's company.** Collect unique company_domain and company_name values surfaced from step 3. Run `match-business` to obtain a business_id per company. Carry both company_name and company_domain forward on every lead row so the persona/ICP scorer can read both.

5. **Fetch account evidence.** Group business_ids into batches of 50 (the `match-business` step from step 4 produces a businesses table; reference it as `--table-name lead_fit_accounts`) and call `enrich-business --session-id <sid> --table-name lead_fit_accounts --type firmographics` for headcount, revenue_range, company_country_code, linkedin_category or naics_category, company_size, company_revenue, company_age, and company description. Capture the new `table_name` returned (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. When the ICP names a tech stack, add `--type technographics` (combine up to 3 enrichments per call: `enrich-business` accepts at most 3). When the ICP cares about funding posture or company stage, add `--type funding-and-acquisitions` likewise.

6. **Pull recent triggers per account.** Call `fetch-businesses-events --session-id <sid> --table-name lead_fit_accounts` (the table populated in step 5) using event types relevant to the persona and ICP, for example new funding rounds, leadership hires in the persona's department, hiring surges in the persona's department, office openings or relocations, product launches, or new partnerships. Use the trigger lookback window from input (default 90 days). For accounts where prospect-level moves matter (recent job change into the persona seat), call `fetch-prospects-events --session-id <sid> --table-name lead_fit_prospects` (the table populated in step 3) over the same window. Tag each event with its age in days so recency weighting is computable downstream.

7. **Optional ICP corroboration.** If the persona/ICP scorer needs to know whether the lead's account looks like the broader ICP shape, run `fetch-entities-statistics` on the ICP filter set once to surface the addressable shape (size bucket distribution, top industries) and attach the summary to the output. Do not re-pull this per lead.

8. **Compose one evidence row per lead.** Each row carries: input identifier, resolution status, prospect_id, full_name, job_title, mapped job_level, mapped job_department, email/professional_email, phone/phone_number, has_email flag, linkedin_url, company_name, company_domain, business_id, headcount, revenue_range, company_country_code, linkedin_category or naics_category, company_size bucket, company_revenue bucket, tech stack hits (only those that intersect the ICP tech list), the top 3 recent events with type, age in days, and one-line summary, the source label as supplied, and any caveat strings (Stale: profile last refreshed >Xmo; Ambiguous match; Failed resolution; Missing phone; Email not found). Process the lead list in chunks of about 25 end-to-end (resolve, fetch person, fetch account, fetch events, write the row, discard raw payloads) so working context does not balloon on long lists.

9. **State the scoring boundary explicitly.** The output ships the per-lead evidence plus the persona and ICP rule set verbatim. Composite scoring and tier assignment (Hot / Warm / Cold) are the caller's job: the caller applies the persona-match, ICP-match, source-weight, and trigger-weight rules to the evidence and produces the tier. Do not invent a composite score from these tools.

## Output Format

### Restated rules
- **Persona:** titles, job_level set, job_department set.
- **ICP filter set:** exact filter object including any autocomplete-canonical values, with the linkedin_category vs naics_category choice and the country vs region_country choice noted.
- **Trigger lookback:** N days.

### Resolution summary
| Input | Resolved name | prospect_id | Status |
|---|---|---|---|
Status legend: Auto-resolved, Verified (caveat), Ambiguous, Failed.

### Per-lead evidence rows
One row per lead, columns:
- full_name, job_title, mapped job_level, mapped job_department
- email or professional_email, phone or phone_number, has_email, linkedin_url
- company_name, company_domain, business_id
- headcount, revenue_range, company_country_code, linkedin_category or naics_category, company_size bucket, company_revenue bucket
- tech_stack_hits (only ICP-listed tech matched)
- top_events (up to 3): type, age_days, one-line summary
- source_label (as supplied)
- caveats

### ICP shape (optional, when step 7 ran)
One block from `fetch-entities-statistics` showing total addressable count for the ICP filter, top size buckets, top industries.

### Scoring rules handed to the caller
- **Persona-match rule:** exact title list / job_level set / job_department set to compare against the lead row.
- **ICP-match rule:** the filter object to compare against the account row.
- **Source weights:** the user-supplied per-source weights if any, otherwise pass through the raw source_label for the caller to weight.
- **Trigger weights:** event-type weights and recency decay the caller wants applied.
- **Tier thresholds:** Hot and Warm cutoffs as supplied.

### Caveats
- Leads with Status = Failed are not scoreable; list them separately.
- Leads with stale profile records (>12 months) are flagged so the caller can downweight title-based persona-fit before dialing.
- Hot-candidate leads missing both phone and professional_email get a "verify contact data before outreach" flag.

## Limitations
- `cost_breakdown.enrichmentDetails` in API responses is cumulative for the session. Per-call cost is in the top-level `cost_in_credits` field. Don't sum `enrichmentDetails` across multiple calls or you'll over-count.
- Resolution from name+company can return multiple plausible matches at large companies; those rows surface as Ambiguous rather than auto-picked.
- Company size and company revenue are bucketed enums, not exact employee or revenue counts; persona/ICP math must work against the bucket.
- linkedin_category and naics_category are mutually exclusive on a single ICP filter; pick one taxonomy per run.
- No built-in scoring engine, no contact data-quality sort, no native employee/revenue sort, no Inc/Fortune ranking signal, no metro taxonomy, and no sub-department job-function filter. Composite scoring and tier assignment are applied by the caller using the evidence rows and the rule set returned here.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in any By-Department breakdown rather than dropping them.
- Map raw `prospect_job_seniority_level` values to canonical filter values for display: `cxo` -> `c-suite`, `vp` -> `vice president`. The `mapped job_level` column in the evidence row should show the canonical value.
