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
- Optional scoping overrides:
  - Country focus (`company_country_code` ISO2 list, or `company_region_country_code` for grouped regions; mutually exclusive).
  - Size override (`company_size` bucket list) or revenue override (`company_revenue` bucket list).
  - Public-only flag (`is_public_company: true`).
  - Restrict by additional `company_tech_stack_tech` IDs the user names explicitly.

If the user gives only a person or asks for similar contacts, redirect them to a prospecting flow. This skill returns accounts, not people.

## Workflow
1. **Resolve the seed.** Call `match-business` with the supplied name or domain. If multiple candidates return, pick the highest-confidence match whose domain aligns with the user input and confirm the chosen `business_id` and display name back in the final output. If nothing resolves, stop and ask the user for a clearer identifier (domain preferred). Sanity check after firmographics lands in step 2: if the resolved business_id's firmographics show a major-brand input but headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity. Re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id - a broken seed produces garbage lookalikes.

2. **Reconstruct the seed profile.** Call `enrich-business` for the matched `business_id` with enrichments `[firmographics, technographics]` in one call (`enrich-business` accepts at most 3 enrichments per call). Capture the new `table_name` returned in the response (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. `linkedin-posts` is NOT needed here. The fields you care about extracting:
   - `linkedin_category` OR `naics_category` (prefer `linkedin_category` if present; the two are mutually exclusive when filtering).
   - `company_size` bucket and `company_revenue` bucket.
   - `company_country_code` (or `company_region_country_code` if the seed is multinational and the user asked for regional scope).
   - Top 3-5 `company_tech_stack_tech` values from the technographics response, biased toward category-defining tools (CRM, MAP, data warehouse, primary cloud) rather than ubiquitous infrastructure (Google Analytics, jQuery, etc.).
   Skip any field that comes back empty; never fabricate a value.

3. **Validate filter inputs.** For each value you plan to pass as a filter, run `autocomplete` to confirm the canonical ID before use:
   - `linkedin_category` or `naics_category` (whichever the seed has).
   - Each `company_tech_stack_tech` token.
   Use only the resolved IDs returned by `autocomplete`; drop any value that does not resolve cleanly. `company_country_code`, `company_region_country_code`, `company_size`, `company_revenue`, and `is_public_company` do NOT require autocomplete.

4. **Apply user overrides.** If the user specified country, size, revenue, public-only, or extra tech filters in `$ARGUMENTS`, replace or extend the reconstructed values with the overrides before the next step. Honor the mutual exclusivity rule between `linkedin_category` and `naics_category`, and between `company_country_code` and `company_region_country_code`.

5. **Size the candidate pool.** Call `fetch-entities-statistics` with `entity_type: "businesses"` and the assembled filter set so you know the universe before pulling rows. If the count is below the requested result size, relax the most restrictive filter first in this order: drop the 5th tech, then the 4th tech, then the 3rd tech, then collapse the size bucket to an adjacent bucket. Re-run statistics after each relaxation step. If the count exceeds 5,000, tighten by adding back tech filters or narrowing region. Report the final candidate count in the output.

6. **Fetch lookalikes.** Call `fetch-entities` with `entity_type: "businesses"`, the validated filter set, and a limit equal to the user-requested count (default 25). Note: `fetch-entities` preview is hard-capped at 5 rows regardless of `--number-of-results`. The full slice only materializes via `export-to-csv` (paid). For interactive use, treat the 5-row preview as a sanity sample, not as the ranked top-N - use `export-to-csv` when the user wants the full lookalike list. Exclude the seed `business_id` from the returned rows before display.

## Output Format
Open with a one-line seed restatement, then a results table, then a brief profile readout and pattern call-outs.

### Header
**Lookalikes for [Seed Company Name] ([seed domain])**
Reconstructed profile: [linkedin_category or naics_category] | [company_size bucket] | [company_revenue bucket] | [country or region] | Tech: [comma-separated tech list].
Candidate pool: [N] companies matching this profile. Returning top [requested count].

### Results Table
| Rank | Company | Domain | Industry | Employees | Revenue | Country |
|------|---------|--------|----------|-----------|---------|---------|
| 1 | company_name | company_domain | linkedin_category or naics_category | company_size | company_revenue | company_country_code |
| 2 | ... | ... | ... | ... | ... | ... |

Show the user-requested count (default 25, cap 100). Always exclude the seed.

### Pattern Notes
After the table, in 2-4 bullets:
- Dominant geography (e.g., "70% US, 20% UK").
- Size concentration (e.g., "skews 201-500 headcount").
- Tech overlap density (how many returned rows actually carry the seed's tech stack, since `company_tech_stack_tech` is filter-based but not always fully populated on every row).
- Any obvious adjacency the filter set introduced (e.g., "industry filter widened to NAICS parent because LinkedIn category was empty on seed").

### Suggested Next Steps
- Pull contacts at any of these accounts by handing them to a prospect-fetch flow scoped via `--businesses-table-name`.
- Deepen one row with `enrich-business` (firmographics, technographics, funding-and-acquisitions, strategic-insights) to compare to the seed.
- Watch the list for signals via `fetch-businesses-events --session-id <id> --table-name <lookalikes_table>` (use the businesses table written by step 6).

## Limitations
- **No native similarity model.** There is no lookalike API or ML similarity score. This skill approximates similarity by reconstructing the seed's firmographics + technographics + industry category, then doing a filtered company fetch on those reconstructed attributes. Results are rank-ordered by `fetch-entities` default ordering, NOT by a true similarity score.
- **No similarity ranking column.** The output table cannot show a per-row similarity score, because none is computed. Rank reflects fetch order, not closeness to the seed.
- **Industry classification gaps.** If the seed has neither `linkedin_category` nor `naics_category` populated, the skill falls back to size + region + tech only, which produces a much looser approximation. Flag this in the output.
- **Tech stack coverage is partial.** `company_tech_stack_tech` is not exhaustively populated across the database, so filtering on multiple tech values can collapse the candidate pool faster than expected. The relaxation logic in step 5 handles this, but the final list may rely on fewer tech anchors than the seed actually uses.
- **Bucketed size and revenue only.** Employee count and revenue are bucket filters, not numeric ranges, so a seed at the high edge of one bucket and a candidate at the low edge of the adjacent bucket can look further apart than they are.
- **Region taxonomy is country-level.** There is no metro or sub-country region filter, so "lookalikes in the same metro" is not possible; the tightest geographic scope is `company_country_code`.
- **No contact-level lookalikes.** The source concept of "similar people" is not supported here; this skill returns accounts only.
