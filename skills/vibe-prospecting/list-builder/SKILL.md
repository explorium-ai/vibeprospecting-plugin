---
name: list-builder
description: Build a targeted list of prospects or businesses from a natural-language brief using Explorium. Use when the user asks to "build a list", "find prospects", "pull a target account list", "give me contacts at", "show me companies that", or names titles, departments, industries, company size, location, tech stack, intent topics, or growth events.
---

# List Builder

Turn a natural-language audience brief into a clean, exportable prospect or business list.

## Input

`$ARGUMENTS` is a free-text description of the audience. Parse it for:

- Entity type (prospects vs businesses; default prospects if ambiguous).
- Role signals: job titles, seniority, department.
- Firmographics: industry, size bucket, revenue bucket, company age, public vs private.
- Geography: country, US/Canadian state, or city region.
- Technographics, intent topics, growth events with a recency window in days.
- Contactability: reachable / emailable.
- Count (default 25), fields requested (e.g. "include phone") that drive which enrichments layer on top.

Example phrasings: "100 VP Engineering at Series B SaaS in the US that use Snowflake", "heads of demand gen at 200-1000 fintech in NYC", "50 CFOs at public manufacturing that raised funding in the last 90 days", "cybersecurity under 500 employees in the UK with intent on zero trust".

## Workflow

1. **Decide list type.** Prospects if the brief names person attributes (title, seniority, department). Businesses if only company attributes are named. If prospects are scoped by a prior company set, plan to thread that businesses table into the prospect fetch.

2. **Discover canonical values.** For every free-text field (industry, technology, job title, intent topic, city region), resolve the user's phrase to the standardized value the API expects. Skip discovery for ISO country codes, region codes, bucket enums (size, revenue, age), seniority and department enums, and boolean flags. **If discovery fails after 2 attempts (varying the bare term, the suffix-qualified term, and the parent category), STOP — do not silently drop the filter or substitute a near-miss.** Surface to the user with two choices: (a) skip this filter and broaden the audience, or (b) abort and reformulate the brief. Never silently substitute or drop a filter the user named.

2b. **Resolution Log.** Maintain a running log of every translation as `<user phrase> → <canonical value | DROPPED | APPROXIMATED as X>` for both successes and failures. This log MUST appear verbatim as the first sub-section of "Search Criteria Applied" in the output. A silent omission is a bug, not a feature.

3. **Tighten loose title filters.** Title filters are not enforced as exact-match: a job-title-only filter for "Vice President of Engineering" can return non-VP rows. Always combine a title with a seniority value (e.g. "vice president") to keep the slice tight.

4. **Size the audience.** Get a total match count for the assembled filters before pulling rows. Use this number to frame the preview honestly and to warn the user early if the audience is unexpectedly small or massive.

5. **Sample-first preview.** Pull a small slice (5 rows) and render it for the user to sanity-check the filter translation before materializing the full list. The interactive preview is hard-capped at 5 rows: treat it as a sanity sample, not as the ranked top-N.

5b. **Cost-budget gate before export.** Before materializing the full list or layering any enrichment, compute the total projected credit cost: `(rows × export_unit) + (rows × enrich_unit per layer requested) + (event_lookups × event_unit)`. Compare against the remaining credit budget for the session. If projected cost exceeds the budget, STOP and present the user with explicit options: (a) reduce row count, (b) drop an enrichment layer, (c) split into multiple sessions, (d) proceed and accept a partial fill. **Never start an export you can't finish** — partial materialization with silent truncation is worse than asking once. The List Summary must include a `Cost: <used>/<budget>` line on every artifact, and if an enrichment promised in the brief was skipped at the gate, declare "Enrichment skipped — budget" as a top-line item, not buried.

6. **Pull the full list.** Once the preview is approved and the cost gate is cleared, materialize the requested count via the paid export path. Restate the audience definition so the user can see what locked in.

7. **Enrich the rows.** For prospects, default to email-only contact enrichment (cheaper); add phone only when the user explicitly asks for it (e.g. dialer flows). Add profile data for LinkedIn URL and bio when requested. Prospect-side LinkedIn post content is NOT available: for recent activity, enrich LinkedIn posts on the employer instead. For businesses, layer in firmographics, technographics, funding, workforce trends, competitive landscape, ratings, or strategic insights based on the fields the user asked for.

8. **Output as a table artifact** with the CSV path called out so the user can download or pipe it onward.

## Output Format

### Search Criteria Applied
Bulleted readout of every filter that landed: entity type, title and seniority, department, industry, size and revenue buckets, geography, tech stack, intent topics, growth events with their recency window, and any boolean flags. Call out any requested filter that had no direct equivalent and how it was approximated.

### Prospect List
Show when entity type is prospects. Columns: name, job title, company, company domain, industry, company size, email (professional preferred), phone if pulled, LinkedIn URL, prospect_id. Drop columns the user did not ask for. Caveat: email and phone only populate after contact enrichment; the discovery preview returns identifiers only.

### Business List
Show when entity type is businesses. Columns: company name, domain, industry, headcount, revenue bucket, country/region, plus any enrichment columns requested (tech stack, recent funding, hiring trend), business_id.

### List Summary
Total matching audience from step 4, rows returned in this pull, path to the CSV artifact, enrichment coverage (e.g. "92 of 100 rows have a verified email"). Frame as "Sample preview (5 of <total> matches)" when a total is available; never invent a total.

### Refinement Options
Concrete next moves: tighten or broaden a bucket, add a reachability filter, swap geography granularity, layer a recent-event filter, pivot from businesses to prospects by reusing the current business table, add or remove an enrichment.

## Limitations

- No native sort by contact data-quality, exact employee count, or revenue. Use the reachability flag, or tighten buckets.
- No metropolitan-area taxonomy: use city region discovery or state-level region codes.
- No native similar-companies tool: see the lookalike-accounts skill.
- No sub-department job-function filter. Combine a title (after discovery) with a department.
- No business-list ranking filter (Inc 5000, Fortune 500). Approximate with size, revenue, and public-company flag.
- Headcount and revenue are bucket enums, not exact numeric ranges.
- Title filters are loose: always pair with a seniority value to avoid false positives.
- The interactive preview is hard-capped at 5 rows: the full slice only materializes via the paid export path.
- Department is null for many cross-functional senior roles (Chief X Officer, President, Founder): group under "Unattributed".
- **No funding-stage filter** (pre-seed, seed, Series A/B/C, etc.). The API exposes funding *events* with dates but not stage labels. Approximate via headcount + revenue bucket + recent funding event and disclose the approximation in the Resolution Log.
- **`fetch-entities-statistics` rejects `company_tech_stack_tech`** despite the schema listing the field. For tech-filtered sizing, use `fetch-entities` (paid) with `number_of_results: 5` as a probe instead of the free statistics endpoint, or size everything else free and treat tech as a paid narrowing step.
- **`fetch-entities-statistics` rejects `city_region`** despite the schema listing it. Metro-scoped sizing must fall back to multi-state region codes (e.g. `company_region_country_code: ["US-NY", "US-NJ"]` for NYC metro). The state-level total overstates metro reality; disclose this.
- **Prospect-side LinkedIn post content is unavailable.** When the user asks for prospect recent activity, declare the limitation in the structured Limitations & Redirects block (see Output Format), then offer the employer-side event enrichment as an explicit substitute. Do not silently redirect without disclosure.

## Limitations & Redirects (output structure)

When any constraint was approximated or unavailable, emit a Limitations & Redirects sub-section formatted as `<limitation> → <what we did instead> → <how to refine>`. This block is the single canonical place for the user to see what we couldn't honor literally — silent approximation without this block is a bug.
