---
name: lookalike-accounts
description: Find companies that resemble a seed account by reconstructing its firmographic, technographic, and industry profile, then surfacing other companies that match those same attributes. Useful for territory expansion, TAM analysis, competitive mapping, account list extension, and finding lookalikes, similar accounts, or audience twins to a reference customer.
---

# Lookalike Accounts

Reconstruct the profile of one seed company, then surface other companies that share its industry, size, region, and tech stack.

## Input

The user supplies via `$ARGUMENTS`:
- A seed company name or domain (required).
- Optional: how many lookalikes to return (default 25, ceiling 100).
- Optional overrides: country focus (country codes or grouped regions, pick one), size or revenue bucket, public-only flag, additional named tech stack components.

If the user gives only a person or asks for similar contacts, redirect them to a prospecting flow. This skill returns accounts.

## Workflow

1. **Resolve the seed — with a mandatory firmographics sanity gate.** Match the supplied name or domain, then **run firmographics enrichment immediately** before treating the seed as resolved. `match-business` can return a phantom `business_id` for nonsense input without erroring; the only way to detect a silent failure is to verify the returned record carries real signal. Treat the seed as resolved ONLY if ALL of these hold: (a) `firmo_name`, `firmo_country`, and `firmo_website` are non-null; (b) `firmo_name` contains a substring of the user input (case-insensitive); (c) the firmographic shape is plausible for a known major brand. If any check fails, STOP and re-prompt the user explicitly: "Did you mean `<firmo_name>` (`<firmo_website>`)? If not, please supply a domain or LinkedIn URL."

2. **Domain-variant sanity check (subset of step 1).** The shell-entity case is a specific failure mode caught by step 1: if a major-brand input resolves to headcount 1-50 with NAICS `551114` (Corporate Managing Offices) or SIC `Hotels and motels`, the match routed to a registered-agent shell. Re-try with the alternate domain or with the company name string. A broken seed produces garbage lookalikes — the firmographics gate in step 1 is the single most important defense against this.

3. **Reconstruct the seed profile.** Enrich firmographics and technographics on the seed. Extract:
   - Industry category (LinkedIn or NAICS, whichever is populated; the two are mutually exclusive as filters).
   - Headcount bucket and revenue bucket.
   - Country code (or regional grouping if the seed is multinational and the user asked for regional scope).
   - Top 3-5 tech stack values, biased toward category-defining tools (CRM, MAP, data warehouse, primary cloud) over ubiquitous infrastructure (Analytics, jQuery).
   Skip any field that comes back empty: never fabricate a value.

4. **Discover canonical values** for the reconstructed industry and each tech token. **Sub-product fallback (mandatory, do NOT silently drop):** if autocomplete returns only sub-product variants of a category-defining tool (e.g. "Datadog Synthetic Monitoring", "Datadog Application Monitoring" but no bare "Datadog"), substitute the most-popular sub-product as a stand-in for the parent vendor and note this in Pattern Notes — never silently drop a category-defining tech because the parent token isn't in the vocabulary. Bucket enums and country codes do not need discovery.

5. **Apply user overrides.** If the user specified country, size, revenue, public-only, or extra tech filters, replace or extend the reconstructed values with the overrides. Honor the mutual exclusivity rule between LinkedIn and NAICS industry, and between country code and grouped region.

6. **Size the candidate pool.** Get a total count for the assembled filters. **Country-filter stats cross-check (mandatory):** `fetch-entities-statistics` does not strictly enforce `company_country_code` — the breakdown can leak out-of-country rows even when a country filter is set. Read the `business_categories_per_location` breakdown and confirm the requested country code's per-location count matches the headline total. If the headline overstates (leakage), treat the country-scoped count as an upper bound and re-confirm by running a `fetch-entities` sample with the same filters before making relaxation decisions. If below the requested return size, relax the most restrictive filter first: drop the 5th tech, then 4th, then 3rd, then collapse the headcount bucket to an adjacent one. Re-size after each step. If the count exceeds 5,000, tighten by adding back a tech filter or narrowing region. Report the final candidate count in the output.

7. **Fetch lookalikes.** Sample the validated filter set to surface candidates, then export the user-requested count via the paid export path for the full materialized list. Exclude the seed before display.

## Output Format

### Header
**Lookalikes for [Seed Company Name] ([seed domain])**
Reconstructed profile: [industry] | [headcount bucket] | [revenue bucket] | [country or region] | Tech: [comma-separated tech list].
Candidate pool: [N] companies matching this profile. Returning top [requested count].
**Note: the `Row` column reflects default fetch order, not a similarity score — all rows match the reconstructed filter set equally.** This skill has no native similarity model; ranking by true closeness to the seed is not available.

### Results Table
| Row | Company | Domain | Industry | Employees | Revenue | Country |
|-----|---------|--------|----------|-----------|---------|---------|

The first column is renamed from `Rank` to `Row` to make it clear the order carries no similarity signal. Show the user-requested count (default 25, cap 100). Always exclude the seed.

### Pattern Notes
2-4 bullets covering dominant geography, size concentration, tech-overlap density (tech filters are not fully populated on every row), and any adjacency the filter set introduced (e.g. "industry widened because LinkedIn category was empty on seed").

### Suggested Next Steps
Pull contacts at any of these accounts via the list-builder flow scoped by the businesses table; deepen one row with the enrich-company flow; watch the list for growth events on the reconstructed cohort.

## Limitations

- **No native similarity model.** There is no lookalike API or ML similarity score. This skill approximates similarity by reconstructing the seed's firmographics, technographics, and industry, then doing a filtered company fetch on those reconstructed attributes. The native flow is match-seed, enrich attributes, then re-fetch with attributes. Results are ranked by default fetch order, NOT by a true similarity score.
- **No similarity ranking column.** No per-row similarity score is computed: rank reflects fetch order.
- **Industry classification gaps.** If neither LinkedIn nor NAICS category is populated, the skill falls back to size + region + tech, producing a looser approximation. Flag this in the output.
- **Tech stack coverage is partial.** Tech tokens are not exhaustively populated, so filtering on multiple values can collapse the candidate pool faster than expected. The relaxation logic in step 6 handles this.
- **Bucketed size and revenue.** A seed at the high edge of one bucket and a candidate at the low edge of the next can look further apart than they are.
- **Region taxonomy is country-level.** No metro or sub-country scope.
- **High-profile execs at these accounts** often have suppressed contact data: if the user pivots to "who runs these", recommend LinkedIn outreach for top execs.
- **No contact-level lookalikes.** This skill returns accounts only.
- **Phantom `business_id` on bogus input.** `match-business` may return a synthetic-looking `business_id` for nonsense seeds without raising an error. The firmographics sanity gate in step 1 (require non-null `firmo_name`, `firmo_country`, `firmo_website` AND `firmo_name` substring-match the user input) is the single defense — it's mandatory, not optional.
- **Output column rename: `Rank` → `Row`.** The first column of the Results Table reflects fetch order, not similarity. The rename and the inline caveat in the Header are both required to prevent users misreading order as ranking.
- **Country-filter leakage on `fetch-entities-statistics`.** The endpoint does not strictly enforce `company_country_code`; cross-check `business_categories_per_location` per step 6 before relying on the headline total for relaxation decisions.
