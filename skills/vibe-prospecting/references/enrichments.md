# Enrichments Reference

Use `enrich` only on JSON inputs that already contain Explorium ids.

## Businesses

- `firmographics`
- `technographics`
- `linkedin_posts`
- `workforce_trends`
- `pc_competitive_landscape_10k`
- `pc_strategy_10k`
- `pc_business_challenges_10k`
- `company_ratings_by_employees`
- `funding_and_acquisition`
- `financial_indicators`
- `company_website_keywords`
- `website_changes`
- `lookalikes`
- `company_hierarchies`
- `webstack`
- `website_traffic`
- `bombora_intent`

## Prospects

- `contacts_information`
- `profiles`
- `linkedin_posts`

## Parameter notes

- `financial_indicators`: requires a date parameter.
- `company_website_keywords`: requires `keywords`.
- `website_traffic`: accepts a `month_period` like `YYYY-MM`.
- `bombora_intent`: accepts `topics` and optional score thresholds.
- `linkedin_posts`: supports an `offline_mode` option in the backend.

## Parameter shape

Pass either one shared parameters object:

```json
{
  "date": "2024-12-31"
}
```

or a per-enrichment map:

```json
{
  "financial_indicators": {
    "date": "2024-12-31"
  },
  "company_website_keywords": {
    "keywords": ["agentic ai", "workflow automation"]
  }
}
```

## Example

```bash
node "$CLI" businesses enrich --input @results.json --enrichments firmographics,technographics --json > /tmp/enriched.json
```
