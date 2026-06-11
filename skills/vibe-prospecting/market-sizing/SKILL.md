---
name: market-sizing
description: Size the total addressable market (TAM) for an Ideal Customer Profile (ICP) against Explorium's 150M+ company universe. Iteratively refine firmographic, technographic, and intent filters with the user until the account universe matches their intent, then return both the count and the working filter set that other skills can consume. Use for territory and capacity design, investor-ready market sizing, and ICP sharpening. Triggers on phrases like "size the market", "TAM for", "addressable market", "how many companies match", "is my ICP too broad", "is my ICP too narrow", "refine my ICP filters", "market sizing".
---

# Market Sizing

Iteratively refine a company-level ICP filter set and return a count plus a structured filter artifact ready for downstream prospecting work.

## Input

- ICP description (recommended): natural language, or "my ICP" / "our ICP" / nothing (ask).
- Use case (optional): territory design, investor sizing, ICP sharpening (default).
- SAM hypothesis inputs (optional): addressable fraction (0 to 1) and ARPA in USD.

## Workflow

1. Parse the ICP into filter dimensions. Tag each user-specified or unspecified. Persona criteria ("CTOs", "VP Sales") are recorded but NOT applied to the company count.
2. Disambiguate ambiguous regions BEFORE counting. "EU" can mean European Union members or the broader European region: ask one clarifying question. Same for "Americas" vs "North America" vs "US and Canada".
3. Discover canonical values for every free-text field (industry, technology, intent topic, city). Industry taxonomy is mutually exclusive: pick LinkedIn industry OR NAICS per pass. For any industry term with zero matches in either taxonomy, surface a "no matching value" message and offer: approximate with a related parent and flag it, seed a known company for a lookalike follow-up, or proceed with a tech-stack or intent proxy on explicit confirmation.
4. Tech-stack taxonomy-gap branch: if a flagship vendor (Snowflake, Databricks, BigQuery) returns zero clean matches after 2-3 query variants, document this as a coverage gap, not a sparsity-narrow result. The skill cannot size around a tech filter with no taxonomy entry.
5. Size the audience. Get the total count for the resolved filter set. Country-scoped TAM caveat: the sizing endpoint does NOT strictly enforce country filters at the headline-count level. For any country-scoped TAM, sum the per-location breakdown across requested ISO-2 codes. Never use the global headline count when the user asked for a specific geography.
6. Data-sparsity probe (mandatory when tech-stack or intent filters are applied). Size twice: with the filter (count_filtered) and without it (count_unfiltered). If count_filtered / count_unfiltered is below 0.1, treat as coverage-sparse and use count_unfiltered as the operative TAM. Surface "Explorium coverage of [field] is sparse for this segment." Show both numbers.
7. Classify the sizing band against the operative TAM.

| Operative TAM | Band | Read |
|---|---|---|
| > 50,000 | Too broad | Probably not operational. |
| 5,000 to 50,000 | Healthy enterprise/mid-market | Suggest tier segmentation. |
| 1,000 to 5,000 | Sweet spot | Focused primary-tier list. |
| 250 to 1,000 | Tight/niche | Flag capacity feasibility. |
| < 250 | Too narrow | Coverage risk; suggest widening. |

8. Sample entities for sanity-check (skip when TAM > 50,000). Pull ~25 rows matching the filter set. Use for: ICP sanity (do top names look right, or include conglomerate / BPO / staffing noise?), directional geography and sub-industry shape, noise-rate estimation. The sample is unsorted: directional, not ranked. Do not compute employee or revenue percentages from it.
9. Noise-adjusted TAM (mandatory when sample noise is at least 20 percent). Compute `adjusted = round(operative_TAM x (1 - noise_rate), 2 sig figs)`. Re-classify the band against the adjusted number. Cite specific noisy rows. 20-60 percent noise signals revisiting the filter set, not shipping the count.
10. SAM hypothesis (only if both inputs supplied). SAM count = operative TAM x addressable fraction. SAM revenue = SAM count x ARPA. Label clearly: hypothesis, not forecast.
11. Self-check: headline rounded to at most 2 sig figs; taxonomy gate cleared; sparsity probe and noise adjustment run when applicable; unspecified dimensions flagged; persona criteria marked "not applied to company TAM"; region disambiguation resolved; refinement options name a specific dimension and an estimated post-refinement count.
12. Present refinement options and loop. Too broad: 2-3 narrowing options with estimated impact. Too narrow: 2-3 widening options. Healthy band: tier segmentation or finalize. Always offer a "save filters" exit so downstream skills can consume the artifact. Re-run from step 3 when filters change and surface the diff. Terminate on finalize.

## Output Format

- TL;DR: use case restated; headline `~[count] companies`; band label. If the sparsity probe fired, show raw filtered, unfiltered, and operative TAM. If noise-adjusted, show raw, noise rate, adjusted, and the band classified against the adjusted number. 1-2 sentences on operational viability, dominant skew, most consequential refinement.
- Filters Applied: dimension, value, and source (user-specified, unspecified, approximation). Persona criteria flagged "NOT applied to company TAM."
- Sample Accounts (optional, only when requested and TAM <= 50,000): up to 25 unsorted rows. Sanity check; name the narrowing filter that removes any noise.
- Sizing Band & Refinement: band label, 1-2 sentences on operational implication, 2-3 refinement options each naming a dimension change and an estimated post-refinement count. Or finalize.
- SAM Hypothesis (only if both inputs supplied): TAM count, addressable fraction, SAM count, ARPA, SAM revenue. Hypothesis, not forecast.
- Final Filter Set (on finalize): structured artifact with resolved values for every applied dimension plus operative TAM, band, pass count, and use case.

## Limitations

- Size and revenue are bucket filters; exact cutoffs cannot be expressed. Revenue buckets appear to be a deterministic employee-to-revenue heuristic, not real revenue data. 90%+ concentration in one bucket is expected; do not slice revenue after locking size.
- No native sort on entity fetch; samples are directional, not ranked.
- No metro taxonomy; geography resolves to country, region, or city autocomplete.
- No similar-companies tool inside this skill; seed-account workflows belong elsewhere.
- No sub-department job-function filter; persona is recorded only, never applied to the company count.
- No Inc / Fortune ranking filters; public-vs-private is the only company-type boolean.
- Industry taxonomy (LinkedIn vs NAICS) and country code vs region-country code are each mutually exclusive on a single query.
