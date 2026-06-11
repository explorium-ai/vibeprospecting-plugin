---
name: list-builder
description: Build a targeted list of prospects or businesses from a natural-language brief using Explorium. Use when the user asks to "build a list", "find prospects", "pull a target account list", "give me contacts at", "show me companies that", or names titles, departments, industries, company size, location, tech stack, intent topics, or growth events.
---

# List Builder

Turn a natural-language audience brief into a clean, exportable prospect or business list backed by Explorium data.

## Input

`$ARGUMENTS` is a free-text description of the audience the user wants. Parse it for:

- Entity type (prospects/contacts vs businesses/companies). If ambiguous, default to prospects.
- Role signals: job titles, seniority (common values: `c-suite`, `vice president`, `director`, `manager`; full enum also includes `owner`, `founder`, `president`, `senior manager`, `board member`, `partner`, `advisor`, etc., consult `fetch-entities --all-parameters` for the full 15-value list), department (`engineering`, `marketing`, `sales`, `it`, `operations`, `finance`, ...; consult `fetch-entities --all-parameters` for the full 29-value enum).
- Firmographics: industry (LinkedIn or NAICS category), company size bucket, revenue bucket, company age, public vs private.
- Geography: country (ISO-2), US/Canadian state (ISO 3166-2), or metro / city region.
- Technographics: tech stack components.
- Growth and timing: business events (funding, hiring, leadership change, product launch) with a `last_occurrence` window in days.
- Intent: `business_intent_topics` keywords.
- Contactability: `has_email: true` when the user asks for "reachable" or "emailable" prospects.

Optional sub-inputs:

- Count: default 25. Sample previews always use 5 rows regardless of requested count.
- Fields requested (e.g. "include phone", "with LinkedIn URL", "company tech stack"): drives which enrichments to layer on top.

Example phrasings:

- "Build a list of 100 VP of Engineering at Series B SaaS companies in the US that use Snowflake."
- "Find heads of demand gen at 200-1000 person fintech companies in NYC."
- "Give me 50 CFOs at public manufacturing companies that raised funding in the last 90 days."
- "Pull a target account list of cybersecurity companies under 500 employees in the UK with intent on zero trust."
- "Show me reachable RevOps managers at e-commerce companies using Shopify."

## Workflow

1. **Determine list type.** Decide `entity_type: "prospects"` or `"businesses"` from the brief. If the user names a person role (title, seniority, department) the list is prospects. If the user only names company attributes, the list is businesses. When prospects are scoped by a prior company set, plan to thread `--businesses-table-name <prior_table>` into the prospect call.

2. **Parse criteria into structured filters.** Map each phrase in the brief to one Explorium filter slot. Enum filters take `{values:[...], negate:false}`; range filters take `{gte:n, lte:n}`; booleans are bare. Remember `linkedin_category` and `naics_category` are mutually exclusive (pick one), as are `company_country_code` and `company_region_country_code`. Use `company_size` buckets (`1-10`, `11-50`, `51-200`, `201-500`, `501-1000`, `1001-5000`, `5001-10000`, `10001+`) and `company_revenue` buckets directly. Encode growth signals as `events: {values:[...], last_occurrence: <days>}`.

3. **Resolve filter values via autocomplete (do NOT guess).** For every free-text field, call `autocomplete` with `field` and `query` to get the standardized string the API expects. Required for: `linkedin_category`, `naics_category`, `company_tech_stack_tech`, `job_title`, `business_intent_topics`, `city_region`. Capture the returned `session_id` and thread it through every subsequent call in this run as `--session-id` so the conversation context is preserved. Skip autocomplete for `company_country_code` (ISO-2), `company_region_country_code` (ISO 3166-2), `company_size`, `company_revenue`, `company_age`, `job_level`, `job_department`, `has_email`, `is_public_company`, and `events`. Intersect `job_title` with `job_level` enum to tighten - the autocomplete-resolved values are not enforced as exact-match (a `job_title`-only filter for `Vice President of Engineering` returned 4 of 5 non-VP rows in live testing). Combine `job_title` with `job_level: {values: ["vice president"]}` for tight matches.

4. **Size the audience.** Call `fetch-entities-statistics` with the assembled filters and the chosen `entity_type` to get a total match count. Use this number to frame the sample preview honestly (e.g. "Sample preview (5 of 12,430 matches)") and to warn the user early if the audience is unexpectedly small or massive.

5. **Sample-first preview on 5.** Call `fetch-entities` with `--number-of-results 5` and `--all-parameters` so the full parameter shape is visible. Pass `--tool-reasoning` describing what audience this slice represents. Render the 5 rows for the user to sanity-check the filter translation before pulling the full list.

6. **Pull the full list.** Once the preview is approved, re-run `fetch-entities` with the requested `--number-of-results N` (default 25) and `--csv` for clean file output. Reuse the same `--session-id`. Pass `--tool-reasoning` restating the audience definition. Note: `fetch-entities` preview is hard-capped at 5 rows regardless of `--number-of-results`. The full slice only materializes via `export-to-csv` (paid). For interactive use, treat the 5-row preview as a sanity sample, not as the ranked top-N. If the user asked for more than the preview cap, use `export-to-csv` for the full materialization.

7. **Enrich the rows.** For prospects, call `enrich-prospects` with the enrichments the brief implies: `contacts` for email (and phone when explicitly requested), `profiles` for LinkedIn and bio. Default to `enrich-prospects --type contacts --contact-types email` (~2 credits per row (email-only) vs ~5 credits per row (email + phone)); switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). Prospect-side linkedin-posts is NOT available; for recent activity, use the business-side `enrich-business --type linkedin-posts`. For businesses, call `enrich-business` with the matching enrichments: `firmographics`, `technographics`, `company-ratings`, `financial-metrics` (requires `parameters.date`), `funding-and-acquisitions`, `challenges`, `competitive-landscape`, `strategic-insights`, `workforce-trends`, `linkedin-posts`, `website-changes`, `website-keywords` (requires `parameters.keywords`), `webstack`, `company-hierarchies`. Both enrichment tools REQUIRE `--session-id` and `--table-name` pointing at the table produced in step 6. The CLI auto-batches 50 IDs per request, so just pass the full table name.

8. **Output as a table artifact.** Present the enriched rows under the sections below, with the CSV file path called out so the user can download or pipe it onward.

## Output Format

### Search Criteria Applied
A bulleted readout of every filter that landed in the final query, including: entity type, role/title filters, seniority/department, industry (LinkedIn or NAICS category), company size and revenue buckets, geography, tech stack, intent topics, business events with their `last_occurrence` window, and any boolean flags (`has_email`, `is_public_company`). Call out any filter the user requested that had no direct Explorium equivalent and how it was approximated.

### Prospect List
Show when `entity_type: "prospects"`. Columns: `full_name`, `job_title`, `company_name`, `company_domain`, `linkedin_category` or `naics_category`, `company_size`, `email` / `professional_email`, `phone` / `phone_number`, `linkedin_url`, `prospect_id`. Drop columns the user did not ask for to keep the table readable. Caveat: `email` / `professional_email` columns only populate after `enrich-prospects-contacts`. The `fetch-entities` preview alone returns discovery fields only - no email values. If displaying these columns from the preview alone, they will be empty.

### Business List
Show when `entity_type: "businesses"`. Columns: `company_name`, `company_domain`, `linkedin_category` or `naics_category`, `headcount` / `company_size`, `revenue_range` / `company_revenue`, country / region, plus any enrichment columns requested (e.g. tech stack, recent funding, hiring trend), `business_id`.

### List Summary
- Total matching audience size from step 4.
- Rows returned in this pull.
- Frame as either "Sample preview (5 of <total> matches)" when statistics returned a total, or "Sample preview (5 rows). Explorium has many more matching these filters." when stats were skipped. Never invent a total.
- Path to the CSV artifact from step 6.
- Enrichment coverage stats (e.g. "92 of 100 rows have a verified email").

### Refinement Options
Concrete next moves the user can pick from:
- Tighten or broaden a specific filter (offer the adjacent `company_size` or `company_revenue` bucket).
- Add a contactability filter (`has_email: true`) if email coverage is thin.
- Swap geography granularity between `company_country_code` and `company_region_country_code`, or layer in `city_region`.
- Layer an `events` filter (e.g. recent funding within 90 days) to focus on in-market accounts.
- Pivot from businesses to prospects (or vice versa) by reusing the current table name as `--businesses-table-name` on the prospect call.
- Add or remove an enrichment (contacts, profiles, technographics, funding-and-acquisitions).

## Limitations

- No native sort by contact data-quality score. Use `has_email: true` as a proxy for reachability.
- No native sort by employee count or revenue. Tighten the `company_size` or `company_revenue` bucket instead.
- No metropolitan-area taxonomy. Use `city_region` autocomplete or `company_region_country_code` at the state level.
- No similar-companies tool. Approximate by running `match-business` on the seed, enriching firmographics + technographics + categories, then re-fetching with those attributes as filters.
- No sub-department job-function filter. Combine `job_title` autocomplete with `job_department`.
- No business-list rankings filter such as Inc 5000 or Fortune 500. Approximate with `company_size` plus `company_revenue` buckets and `is_public_company`.
- Employee count and revenue are bucket enums, not exact numeric ranges.
- `is_public_company` boolean is the only company-type filter available.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in any By-Department breakdown rather than dropping them.
- Map raw `prospect_job_seniority_level` values to canonical filter values for display: `cxo` -> `c-suite`, `vp` -> `vice president`.
