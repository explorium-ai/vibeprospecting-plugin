---
name: market-sizing
description: Size the total addressable market (TAM) for an Ideal Customer Profile (ICP) against Explorium's 150M+ company universe. Iteratively refine firmographic, technographic, and intent filters with the user until the account universe matches their intent, then return both the count and the working filter set that other skills can consume. Use for territory and capacity design, investor-ready market sizing, and ICP sharpening. Triggers on phrases like "size the market", "TAM for", "addressable market", "how many companies match", "is my ICP too broad", "is my ICP too narrow", "refine my ICP filters", "market sizing".
---

# Market Sizing

Iteratively refine a company-level ICP filter set and return a count plus a structured filter artifact ready for downstream prospecting work. Each pass returns a count, a banded sizing read, optional sample views for sanity-check, and concrete refinement options. Terminates when the user finalizes.

## Input

- ICP description (recommended): natural language, or "my ICP" / "our ICP" / nothing (ask the user to describe it).
- Use case (optional): territory design / investor sizing / ICP sharpening (default).
- SAM hypothesis inputs (optional): `addressable_fraction` (0 to 1) and `arpa_usd`.

## Workflow

### 1. Parse the ICP into filter dimensions
Reconcile user text into Explorium filter fields. Tag every dimension as `user-specified` or `unspecified`. Persona criteria like "CTOs" or "VP Sales" are recorded but NOT applied to the company count, since they describe who you sell into, not who the account is. Persona discovery belongs to a prospect-side skill once the filter set is settled.

### 2. Disambiguate ambiguous regions BEFORE the count
- "EU" can mean European Union member states or the broader European region. Ask one clarifying question if unclarified.
- "Americas" vs "North America" vs "US and Canada": confirm if uncertain.
- Note that `company_country_code` and `company_region_country_code` are mutually exclusive on the same query.

### 3. Resolve free-text values via autocomplete (mandatory)
For every value that targets one of these fields, call `autocomplete` first and use only resolved values:
- `linkedin_category` (LinkedIn industry taxonomy)
- `naics_category` (NAICS codes)
- `company_tech_stack_tech` (technographics)
- `job_title` (persona, recorded only)
- `business_intent_topics`
- `city_region`

Bucket and boolean fields do NOT need autocomplete: `company_country_code`, `company_region_country_code`, `company_size`, `company_revenue`, `company_age`, `job_level`, `job_department`, `has_email`, `is_public_company`, events.

Mutually exclusive: `linkedin_category` vs `naics_category`. Pick one industry taxonomy per query.

#### Taxonomy-gap gate (mandatory)
For every industry term the user gives, call `autocomplete` against both `linkedin_category` and `naics_category` (separately, on different passes):
- One or more matches: use the resolved value in the filter.
- Zero matches in both taxonomies: surface "No matching industry value in Explorium's taxonomy for `<term>`." Recommend one of: (a) approximate with a related parent category and flag the approximation, (b) seed a known company and offer a lookalike-style follow-up, (c) explicit user confirmation to proceed with a tech-stack or intent proxy. Wait for confirmation.

Tech-stack taxonomy-gap branch: if `company_tech_stack_tech` autocomplete returns zero clean matches after 2-3 query variants for a flagship vendor (Snowflake, Databricks, BigQuery, etc.), document this as a coverage gap rather than treating it as a sparsity-narrow result. The skill cannot size around a tech filter that has no taxonomy entry.

### 4. Get the count
Call `fetch-entities-statistics` with entity type `businesses` and the resolved filter set. This is the load-bearing tool; it returns the total count for the filter set without paging sample rows. Capture the number as `count_filtered`.

Country-scoped TAM caveat (load-bearing): `fetch-entities-statistics` does NOT strictly enforce the `company_country_code` filter. `total_results` in the response is the GLOBAL count for the non-country filters; the per-country count is in `stats.business_categories_per_location[<category>][<country>]`. For any country-scoped TAM use the per-location breakdown, NEVER `total_results`. Sum across the requested ISO-2 codes in the per-location map to get the operative country-scoped count.

#### Data-sparsity probe (mandatory when tech_stack or intent filters applied)
Explorium coverage of `company_tech_stack_tech` and `business_intent_topics` is sparse in some segments. A filter collapsing the count to 0 may be a coverage gap, not a narrow ICP.

1. Run `fetch-entities-statistics` with the filter (`count_filtered`).
2. Run `fetch-entities-statistics` again without the tech-stack or intent filter, all other filters intact (`count_unfiltered`).
3. If `count_filtered / count_unfiltered < 0.1` (filter drops more than 90 percent):
   - Treat as coverage-sparse, not narrow ICP.
   - Use `count_unfiltered` as the operative TAM for banding.
   - Surface "Explorium coverage of [field] is sparse for this segment. Filtered: X. Operative TAM: Y (unfiltered)."
4. Otherwise `count_filtered` is the operative TAM.

Both numbers always shown.

### 5. Classify the sizing band

| Operative TAM | Band | Read |
|---|---|---|
| > 50,000 | Too broad | Probably not operational. |
| 5,000 to 50,000 | Healthy enterprise/mid-market | Suggest tier segmentation. |
| 1,000 to 5,000 | Sweet spot | Focused primary-tier list. |
| 250 to 1,000 | Tight/niche | Flag capacity feasibility. |
| < 250 | Too narrow | Coverage risk; suggest widening. |

### 6. Optional sanity-check sample (skip when TAM > 50,000)
Only when the user wants visual confirmation of fit, call `fetch-entities` with entity type `businesses`, the same filter set, and a page size of 25. Use it for:
- ICP sanity check: do the top names look like the ICP, or contain conglomerate / BPO / staffing noise?
- Geographic and sub-industry shape: directional only.
- Noise-rate estimation: count rows in the top 25 that visibly don't match the ICP. Rate = `noisy_rows / 25`.

`fetch-entities` does not support sort, so this sample is NOT a ranked or revenue-skewed view; treat it as a directional slice only. Do not compute employee-band or revenue-band percentages from this sample.

#### Noise-adjusted TAM (mandatory when sample noise is at least 20 percent)
- `tam_noise_adjusted = round(count_operative × (1 − noise_rate), 2 sig figs)`.
- Re-classify the band against `tam_noise_adjusted`.
- Cite specific noisy rows ("of top 25, 6 are wineries or solar installers").
- Report order: raw count → noise rate → adjusted TAM → band.

20 to 60 percent noise is common when an industry term resolves loosely; treat it as a stronger signal to revisit the filter set than to ship the count.

### 7. SAM hypothesis (only if both inputs supplied)
- SAM count = operative TAM × `addressable_fraction`
- SAM revenue = SAM count × `arpa_usd`
- Label clearly: Hypothesis, not forecast.

### 8. Self-check before output
- Headline count rounded to no more than 2 significant figures.
- Taxonomy-gap gate cleared for every industry term, or user explicitly approved a proxy.
- Data-sparsity probe run when tech-stack or intent filters were applied.
- Noise-adjusted TAM computed when sample noise was at least 20 percent.
- Every unspecified dimension flagged.
- Persona criteria marked "not applied to company TAM."
- Region disambiguation resolved.
- Refinement options name a specific dimension and an estimated post-refinement count.

### 9. Present refinement options and loop
- Too broad (>50k): two or three narrowing options with estimated impact.
- Too narrow (<250): two or three widening options.
- Healthy band: tier segmentation or finalize.
- Always offer a "save filters" exit so downstream skills can consume the artifact.

Re-run from step 3 when filters change. Surface the filter-set diff each pass. Terminate on finalize or hand-off.

## Output Format

### TL;DR: Market Sizing for [ICP one-liner] · Pass [N]

Use case: [restate].

Headline. ~[count] companies. Band: [too broad / healthy / sweet spot / tight / too narrow].

If data-sparsity probe fired: `Raw filtered: X · Unfiltered: Y · Operative TAM: Y (filter is coverage-sparse).`

If noise-adjusted: `Raw: A · Sample noise: ~B% · Noise-adjusted: C` (band classified against C).

Read. [1 to 2 sentences: operational? dominant skew? most consequential refinement?]

This pass's filter diff: [for pass N>1]

### Filters Applied

| Dimension | Filter field | Value | Source |
|---|---|---|---|

`Source` legend: `user-specified` · `unspecified` · `approximation`. Persona criteria flagged "NOT applied to company TAM."

### Sample Accounts (optional, only if requested and TAM <= 50,000)

Up to 25 rows from `fetch-entities`. Unsorted slice, directional only.

| # | Company | Industry | Size bucket | Country |

Sanity check. Do these look like the ICP, or include conglomerate / BPO / staffing noise? If noise, name the specific narrowing filter that removes it.

### Sizing Band & Refinement

Band: [label].
Why this band. [1 to 2 sentences on count and operational implication.]
Refinement options:
1. [Dimension change + estimated post-refinement count]
2. [Alternative]
3. [Optional]

Or: finalize and hand off the filter set.

### SAM Hypothesis (only if both inputs supplied)

Hypothesis, not forecast.

| Metric | Value |
|---|---|
| TAM count | |
| Addressable fraction | |
| SAM count | |
| ARPA (USD) | |
| SAM revenue | |

### Final Filter Set (on finalize)

```json
{
  "filters": {
    "linkedin_category": {"values": ["..."], "negate": false},
    "company_size": {"values": ["..."], "negate": false},
    "company_revenue": {"values": ["..."], "negate": false},
    "company_country_code": {"values": ["..."], "negate": false},
    "company_tech_stack_tech": {"values": ["..."], "negate": false},
    "business_intent_topics": {"values": ["..."], "negate": false}
  },
  "_meta": {"tam_count": 0, "band": "...", "pass_count": 0, "use_case": "..."}
}
```

## Limitations

- Employee size and revenue are bucket filters only; exact-number cutoffs cannot be expressed.
- `company_revenue` bucket distribution appears to be a deterministic employee-to-revenue heuristic, not real revenue data. 90%+ concentration in a single bucket for a tightly-scoped query is expected. Do not slice by `company_revenue` after locking `company_size` - the cut will be non-informative.
- No native sort on `fetch-entities`, so sample views are directional slices, not ranked lists.
- No metro-area taxonomy; geography resolves to country, region, or `city_region` (autocomplete).
- No similar-companies tool inside this skill; a seed-account workflow belongs to a separate skill.
- No sub-department job-function filter; persona refinement is recorded only, never applied to the company count.
- No Inc / Fortune ranking filters; `is_public_company` is the only company-type boolean.
- `linkedin_category` and `naics_category` are mutually exclusive on the same query; pick one taxonomy per pass.
- `company_country_code` and `company_region_country_code` are mutually exclusive on the same query.
