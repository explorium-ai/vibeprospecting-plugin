---
name: enrich-company
description: Pull a single company's full profile in Explorium. Accepts a domain, company name, or business_id and returns firmographics, technographics, financial metrics, funding history, workforce trends, competitive landscape, and the contact pool count.
---

# Enrich Company

Resolve a single company to its Explorium business_id and return a complete profile across firmographics, tech, financials, funding, hiring, and contact coverage.

## Input

The user will provide one of:
- A domain (e.g. `stripe.com`, `https://stripe.com`)
- A company name (e.g. `Stripe`)
- A known Explorium `business_id`

Optional:
- A specific area of focus (e.g. "just funding", "tech stack only"). If omitted, run the full profile.

## Workflow

1. **Resolve to a business_id.**
   - Domain input: call `match-business` with the domain. Use the returned `business_id` directly.
   - Company name input: call `match-business` with the name. If the match is ambiguous or low-confidence, re-run `match-business` with the name plus any user-supplied tiebreakers (country, HQ city, domain hint). Surface the top 3 candidates (name, domain, country, headcount) and ask the user to pick before continuing. Do not use `company_name` as a filter on `fetch-entities`; it is not a valid filter field. `match-business` is the only resolution path for a name.
   - business_id input: skip resolution and treat the value as the table seed.
   - If nothing resolves, stop and tell the user no business matched; suggest re-trying with a domain.
   - Sanity check after firmographics enrichment lands in step 3: if the resolved business_id's firmographics show a major-brand input but headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity. Re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id.

2. **Stage the seed row.** All enrichment tools require `--session-id` and `--table-name`. Capture both from the `match-business` (or `fetch-entities`) response and reuse them for every enrich call below. The single resolved row is the table.

3. **Run the core profile bundle in chunked `enrich-business` calls (max 3 enrichments per call).** Pass `--session-id` and `--table-name` from step 2. Capture the new `table_name` returned in the response (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. `enrich-business` accepts at most 3 enrichments per call. Call in three batches:
   - Call 1: `[firmographics, technographics, company-hierarchies]` (industry/headcount/HQ/type/firmo_ticker, detected tech stack, parent/subsidiaries).
   - Call 2: `[funding-and-acquisitions, workforce-trends, strategic-insights]` (funding rounds, headcount trajectory, priorities).
   - Call 3: `[company-ratings, competitive-landscape]` (third-party ratings, named competitors).

4. **Add financial-metrics with a date parameter.** `financial-metrics` requires `parameters.date` in ISO 8601 form (e.g. `2024-01-01T00:00`); use the first day of the current month (or the most recent month the user names). Call `enrich-business` again on the latest view-table from step 3 with `enrichments: financial-metrics` and the date parameter.

5. **Count the addressable contact pool.** Call `fetch-entities-statistics` with `entity_type: prospects` and `filters.business_id.values: [<resolved business_id>]`. Note: `fetch-entities-statistics` does NOT support `--businesses-table-name`; that flag only works on `fetch-entities`. Scope stats with `filters.business_id.values` directly. This scopes prospect counts to the resolved company without enumerating rows. Record the total as "Contacts in Explorium".

6. **Optional focused mode.** If the user asked for one slice only (e.g. "just tech stack", "funding only"), skip the unrelated enrichments in steps 3 and 4 but still run steps 1, 2, and 5.

7. **Render the profile.** Use the output format below. Always include the `business_id` and `company_domain` so the user can chain into follow-up work (contact pulls, signals, hiring trends).

## Output Format

**[Company Name]** - [one-line description from strategic-insights or firmographics]

| Field | Value |
|-------|-------|
| Website | company_domain |
| Industry (LinkedIn) | linkedin_category |
| Industry (NAICS) | naics_category |
| Headcount Bucket | company_size |
| Exact Headcount | headcount (if returned) |
| Revenue Bucket | company_revenue |
| Revenue Range | revenue_range (if returned) |
| HQ Location | city, region, country |
| Company Type | public / private / subsidiary |
| Ticker (if public) | firmo_ticker |
| Phone | phone_number |
| business_id | business_id |

**Corporate Structure**
- Ultimate Parent: from company-hierarchies
- Parent: from company-hierarchies
- Subsidiaries: count and top names

**Financials**
- Reporting period: parameters.date
- Key metrics from financial-metrics (revenue, growth, margin where present)

**Funding & Acquisitions**
- Total raised, last round (stage, amount, date, lead investor)
- Recent acquisitions made or received

**Workforce Trends**
- Headcount now vs 6 / 12 / 24 months ago
- Net hires last quarter, top hiring departments

**Tech Stack** (technographics)
- Group by category (CRM, analytics, infra, etc.), cap at top 15 named tools

**Competitive Landscape**
- Top named competitors and positioning notes

**Strategic Insights**
- 3-5 bullets summarizing recent direction, priorities, or signals

**Ratings**
- Glassdoor / G2 / review signals from company-ratings

**Contact Coverage**
- Contacts in Explorium: <count from fetch-entities-statistics>
- Suggest next step: pull decision-makers with `fetch-entities entity_type: prospects --businesses-table-name <table>` filtered by `job_level` and `job_department`.

Always show the `business_id` and `company_domain` at the top so they can be reused.

## Limitations

- `strategic-insights` and `challenges` enrichments are sourced from SEC 10-K filings; for private companies these will be all-null, and for public companies the data can be 12-18 months stale. Use `fetch-businesses-events`, `funding-and-acquisitions`, `workforce-trends`, and `linkedin-posts` for current-state signals.
- Exact headcount and exact revenue are not always returned; `company_size` and `company_revenue` are bucketed values, not raw numbers.
- No native "similar companies" tool. To approximate, take the resolved firmographics (linkedin_category or naics_category, company_size, company_country_code) and run `fetch-entities entity_type: businesses` with those filters, then enrich the result set.
- Growth percentages depend on what `workforce-trends` returns; quarter-over-quarter and year-over-year deltas may be partial for smaller or private companies.
- `financial-metrics` requires a `parameters.date`; if the user does not provide one, default to the current month and state the assumption.
- Sub-industry granularity is limited to whichever taxonomy you filtered on (linkedin_category and naics_category are mutually exclusive in filters, though both can appear in the firmographics enrichment output).
