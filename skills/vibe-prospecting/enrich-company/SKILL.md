---
name: enrich-company
description: Pull a single company's full profile in Explorium. Accepts a domain, company name, or business_id and returns firmographics, technographics, financial metrics, funding history, workforce trends, competitive landscape, and the contact pool count.
---

# Enrich Company

Resolve a single company and return a complete profile across firmographics, tech, financials, funding, hiring, and contact coverage.

## Input

The user will provide one of:
- A domain (e.g. `stripe.com`)
- A company name (e.g. `Stripe`)
- A known Explorium `business_id`

Optional: a specific area of focus (e.g. "just funding", "tech stack only"). If omitted, run the full profile.

## Workflow

1. **Resolve the company.** Match the business from the supplied domain, name, or id. If a `business_id` is given, treat it as already resolved. `match-business` returns one silent winner with no confidence score and no runner-up candidates — there is NO "top-N matches" API mode, so do not promise the user a 3-candidate pick the tool surface can't deliver.

1a. **Confidence gate — when to stop and ask.** After match, before spending any further credits, run a deterministic confidence check. Stop and ask the user for a domain disambiguator if ANY of these hold:
   - headcount 1-50 AND (NAICS in {`551114`, `561110`} OR SIC in {`Hotels and motels`, `Legal services`}) — almost always a registered-agent shell;
   - resolved `firmo_name` does not contain a substring of the user-supplied string (case-insensitive);
   - resolved domain root-label differs from the user-supplied domain by Levenshtein distance > 3;
   - `firmo_country` or `firmo_website` is null.
   Re-prompt: "Resolved to `<firmo_name>` (`<firmo_website>`, `<firmo_country>`). Is that the right company?" Do not invent alternates the API did not return.

2. **Domain-variant sanity check.** After firmographics land, if a major-brand input resolves to a row with headcount 1-50 and NAICS `551114` (Corporate Managing Offices) or SIC `Hotels and motels`, the match likely routed to a registered-agent shell. Re-try with the alternate domain or with the company name string before continuing.

3. **Enrich the core profile with public/private branching.** The 10-K-derived enrichments (`strategic-insights`, `challenges`, `competitive-landscape`, `company-ratings`) are NULL for private companies and 12-18 months stale for public ones — running them blindly burns 2 credits/row per null section.

   **Branch on firmographics first:**
   - If `firmo_company_type` is `private` (or `firmo_ticker` is null), SKIP strategic-insights, challenges, competitive-landscape, and company-ratings. Synthesize the "Strategic Insights" output section from `fetch-businesses-events` (last 12 months) + funding history instead. Label the section header `Strategic Insights (signal-derived — no 10-K available)`.
   - If `firmo_company_type` is `public` AND the last 10-K date is within 12 months: run all the 10-K enrichments normally.
   - If `firmo_company_type` is `public` BUT the last 10-K date is more than 12 months ago: run them, but label the section `Strategic Insights (10-K dated YYYY-MM — supplement with recent events)`.

   **Always run** (regardless of branch): firmographics, technographics, company hierarchies, funding-and-acquisitions, workforce-trends.

4. **Add financial metrics.** Financial metrics require a reporting date. Default to the first day of the current month, or use the most recent month the user names, and state the assumption.

5. **Size the contact pool (current-employment scope).** Get a prospect count scoped to the resolved company. **Use the business domain (not `business_id`) as the scoping filter** — `business_id` on prospect searches returns *associated* people, including former employees whose latest experience still references this id, which inflates the coverage estimate. The domain-scoped count is closer to "current employees" semantics. Label the result `Contacts at this company (current employment)` to avoid implying former-employee inclusion. Note the underlying field caveat in the output: alumni leakage is a known data behavior (see Bug 11 in the API-bugs tracker).

   **Enrichment chunking discipline.** Across step 3 plus this step plus any chained downstream enrichments, the per-session column count is bounded by SQLite (Bug 3). Run wide enrichments in two batches with a fresh session between them: **Batch A** — firmographics, technographics, hierarchies, ratings. **Batch B** — funding, workforce, strategic insights, competitive. Do not chain a 5th wide enrichment into the same session as Batch A or B.

6. **Focused mode.** If the user asked for one slice only (e.g. "just tech stack", "funding only"), run only the relevant enrichments in step 3 plus steps 1, 2, and 5.

7. **Render the profile** using the format below. Always surface `business_id` and `company_domain` so the user can chain into follow-up work.

## Output Format

**[Company Name]** : [one-line description from strategic insights or firmographics]

| Field | Value |
|-------|-------|
| Website | domain |
| Industry | LinkedIn or NAICS category |
| Headcount | bucket plus exact count when present |
| Revenue | bucket plus range when present |
| HQ Location | city, region, country |
| Company Type | public / private / subsidiary |
| Ticker | if public |
| Phone | |
| business_id | |

**Corporate Structure**: ultimate parent, direct parent, subsidiary count and top names.
**Financials**: reporting period plus key metrics (revenue, growth, margin where present).
**Funding & Acquisitions**: total raised, last round (stage, amount, date, lead investor), recent acquisitions.
**Workforce Trends**: headcount now vs 6 / 12 / 24 months ago, net hires last quarter, top hiring departments.
**Tech Stack**: group by category (CRM, analytics, infra), cap at top 15 named tools.
**Competitive Landscape**: top named competitors and positioning notes.
**Strategic Insights**: 3-5 bullets on recent direction, priorities, or signals.
**Ratings**: Glassdoor, G2, and other review signals when returned.
**Contact Coverage**: total prospect count plus a suggested next step to pull decision-makers filtered by seniority and department.

## Limitations

- Strategic insights and challenges are sourced from SEC 10-K filings: null for private companies, and 12-18 months stale for public ones. Use business events, funding, workforce trends, and LinkedIn posts for current-state signals.
- Exact headcount and exact revenue are not always returned: bucket values are the floor.
- No native "similar companies" tool. Approximate by reconstructing seed attributes and re-fetching with those filters (see the lookalike-accounts skill).
- Quarter-over-quarter and year-over-year headcount deltas may be partial for smaller or private companies.
- Financial metrics require a reporting date: default to current month and state the assumption.
- High-profile executives at the resolved company often have suppressed contact data. If the user pivots to "who runs it", warn that professional emails for top execs are unreliable and recommend LinkedIn outreach for that tier.
- Sub-industry granularity is limited to whichever taxonomy you filtered on (LinkedIn and NAICS categories are mutually exclusive as filters, though both can appear in firmographics output).
- **`match-business` returns one silent winner with no confidence score and no runner-up candidates.** The confidence gate in step 1a (headcount + NAICS/SIC heuristics, Levenshtein name check, null `firmo_country`/`firmo_website`) is the operational substitute for the unimplementable "top 3 candidates" pattern. Do not invent alternates the API did not return.
- **10-K-derived enrichments (strategic-insights, challenges, competitive-landscape, company-ratings) are null for private companies** and 12-18 months stale for public ones. The public/private branching in step 3 substitutes business events + funding history for private targets and labels the output section "Strategic Insights (signal-derived — no 10-K available)".
- **Per-session column count is bounded by SQLite.** Running 5+ wide enrichments in one session triggers a column-count error (Bug 3). The two-batch enrichment discipline in step 3/5 (firmographics + technographics + hierarchies + ratings; reset; funding + workforce + strategic + competitive) is mandatory for full-profile runs.
- **Contact-pool count uses domain-scoped, not `business_id`-scoped, prospect counts.** `business_id` on prospect searches returns *associated* people including former employees (Bug 11), which inflates coverage estimates. The domain-scoped count better approximates "current employees".
