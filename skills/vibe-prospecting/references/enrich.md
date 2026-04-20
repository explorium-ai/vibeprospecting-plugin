# Enrich

Use enrich commands after you have business or prospect IDs.

Optional **`session_id`** in `--args`: same value as the fetch or match that produced the IDs when still fulfilling one user request.

Cowork enrich responses return stringified payloads under `enrichment_results`. Capture raw JSON first. Do not assume `--save-csv` will work for cowork enrich calls.

Before any `--save-csv` call, set `TMPDIR` to a writable sandbox path, for example `TMPDIR=/sessions/<id>/tmp-vpai`, then `mkdir -p "$TMPDIR"`.

## `enrich-business`

Requires business IDs from `match-business` or `fetch-entities` with `"entity_type":"businesses"`. Runs all requested enrichments in parallel.

Practical limit: batch `business_ids` in chunks of 50 or less.

```bash
# Full company intelligence
npx @vibeprospecting/vpai@latest enrich-business --args '{
  "session_id": "session_from_match_or_fetch",
  "business_ids": ["biz_abc123"],
  "enrichments": ["firmographics","technographics","funding-and-acquisitions","workforce-trends","linkedin-posts"]
}' --tool-reasoning 'Find company details and enrichment data for the requested businesses'

# Tech stack deep dive with keyword check
npx @vibeprospecting/vpai@latest enrich-business --args '{
  "session_id": "session_from_match_or_fetch",
  "business_ids": ["biz_abc123"],
  "enrichments": ["technographics","webstack","website-keywords"],
  "parameters": {"keywords": ["AI","machine learning","LLM"]}
}' --tool-reasoning 'Find company details and enrichment data for the requested businesses'

# Public company financials (requires date parameter)
npx @vibeprospecting/vpai@latest enrich-business --args '{
  "session_id": "session_from_match_or_fetch",
  "business_ids": ["biz_abc123"],
  "enrichments": ["financial-metrics","competitive-landscape","strategic-insights"],
  "parameters": {"date": "2024-01-01T00:00"}
}' --tool-reasoning 'Find company details and enrichment data for the requested businesses'
```

Enrichment types:
`firmographics`, `technographics`, `company-ratings`, `financial-metrics`, `funding-and-acquisitions`, `challenges`, `competitive-landscape`, `strategic-insights`, `workforce-trends`, `linkedin-posts`, `website-changes`, `website-keywords`, `webstack`, `company-hierarchies`

- `financial-metrics` requires `parameters.date`
- `website-keywords` requires `parameters.keywords`
- For finding specific people at a company, use `fetch-entities` with `"entity_type":"prospects"` and `business_id` instead of enrichment

## `enrich-prospects`

Requires prospect IDs from `match-prospects` or `fetch-entities` with `"entity_type":"prospects"`. Always combine all needed enrichments in one call.

Hard limit: `enrich-prospects` accepts at most 50 `prospect_ids` per call, even if a schema snapshot appears to allow 100. Batch prospect enrichment in chunks of 50 or less.

```bash
# Full profile
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"session_id":"session_from_match_or_fetch","prospect_ids":["pro_xyz789"],"enrichments":["profiles","contacts","linkedin-posts"]}' --tool-reasoning 'Find people details and contact data for the requested prospects'

# Just contact details for multiple people
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"session_id":"session_from_match_or_fetch","prospect_ids":["pro_xyz789","pro_abc123"],"enrichments":["contacts"]}' --tool-reasoning 'Find people details and contact data for the requested prospects'
```

Enrichment types:
`contacts` (emails, phones), `profiles` (name, role, work history, education), `linkedin-posts` (posts and engagement)

## `enrich-* --save-csv` caveat

Do not rely on `--save-csv` for cowork `enrich-business` or `enrich-prospects`. The CSV extractor expects row arrays, but cowork enrich payloads are stringified inside `enrichment_results`.

- Capture raw JSON and inspect only the fields you need.
- Reuse the same `session_id` across the match/fetch -> enrich chain when it belongs to one user request.

## Parsing Responses

Capture the raw response, then read the specific fields you need from `enrichment_results`.

```bash
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"session_id":"session_from_match_or_fetch","prospect_ids":["pro_1"],"enrichments":["contacts"]}' --tool-reasoning 'Find people details and contact data for the requested prospects' > /tmp/enrich.json 2>&1
python3 -c 'import json; d=json.load(open("/tmp/enrich.json")); print(d["enrichment_results"]["contacts"])'
```

## `challenges` Categories

The `challenges` enrichment returns optional list-valued categories extracted from company 10-K filings. Common fields include:

- `technological_disruption` - AI / technology-change risk
- `company_data_security_breach` - cyber incident risk
- `company_data_security_privacy` - privacy / regulatory risk
- `company_information_systems` - IT / infrastructure risk
- `company_reliance_on_third_parties` - vendor / partner dependency risk
- `company_supply_chain` - supply chain risk
- `company_competition` - competitive pressure
- `company_customer_adoption` - adoption / demand risk
- `company_market_saturation` - market saturation risk

Use `link_to_filing_details` to trace each extracted category back to the source filing.
