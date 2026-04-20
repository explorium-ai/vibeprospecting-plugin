# Enrich

Use enrich commands after you have business or prospect IDs.

Add `--save-csv` when you want enrichment rows written to CSV. Enrich responses can include multiple enrichment tables, so the CLI may return `files` with one CSV per enrichment key, each with its own schema.

## `enrich-business`

Requires business IDs from `match-business` or `fetch-entities` with `"entity_type":"business"`. Runs all requested enrichments in parallel.

```bash
# Full company intelligence
npx @vibeprospecting/vpai@latest enrich-business --args '{
  "business_ids": ["biz_abc123"],
  "enrichments": ["firmographics","technographics","funding-and-acquisitions","workforce-trends","linkedin-posts"]
}'

# Tech stack deep dive with keyword check
npx @vibeprospecting/vpai@latest enrich-business --args '{
  "business_ids": ["biz_abc123"],
  "enrichments": ["technographics","webstack","website-keywords"],
  "parameters": {"keywords": ["AI","machine learning","LLM"]}
}'

# Public company financials (requires date parameter)
npx @vibeprospecting/vpai@latest enrich-business --args '{
  "business_ids": ["biz_abc123"],
  "enrichments": ["financial-metrics","competitive-landscape","strategic-insights"],
  "parameters": {"date": "2024-01-01T00:00"}
}'
```

Enrichment types:
`firmographics`, `technographics`, `company-ratings`, `financial-metrics`, `funding-and-acquisitions`, `challenges`, `competitive-landscape`, `strategic-insights`, `workforce-trends`, `linkedin-posts`, `website-changes`, `website-keywords`, `webstack`, `company-hierarchies`

- `financial-metrics` requires `parameters.date`
- `website-keywords` requires `parameters.keywords`
- For finding specific people at a company, use `fetch-entities` with `"entity_type":"prospect"` and `business_id` instead of enrichment

## `enrich-prospects`

Requires prospect IDs from `match-prospects` or `fetch-entities` with `"entity_type":"prospect"`. Always combine all needed enrichments in one call.

```bash
# Full profile
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"prospect_ids":["pro_xyz789"],"enrichments":["profiles","contacts","linkedin-posts"]}'

# Just contact details for multiple people
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"prospect_ids":["pro_xyz789","pro_abc123"],"enrichments":["contacts"]}'
```

Enrichment types:
`contacts` (emails, phones), `profiles` (name, role, work history, education), `linkedin-posts` (posts and engagement)
