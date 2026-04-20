# Fetch

Use fetch commands to search for businesses or prospects, retrieve event details, or run general web search.

In cowork mode, use `fetch-entities` for both business and prospect search. Set `entity_type` to `business` or `prospect`.

Optional **`session_id`** in `--args`: reuse the value from the previous tool in the same user task when chaining after autocomplete, match, or an earlier fetch.

Add `--save-csv` when you want the returned `data[]` rows written to a CSV file. The CLI will return JSON with the CSV path and column list.

## `fetch-entities` for businesses

```bash
# US software companies with 51-200 employees
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "business",
  "filters": {
    "country_code": {"values": ["US"]},
    "company_size": {"values": ["51-200"]},
    "linkedin_category": {"values": ["Software Development"]}
  }
}'

# Companies using Salesforce, excluding UK
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "business",
  "filters": {
    "company_tech_stack_tech": {"values": ["Salesforce"]},
    "country_code": {"values": ["GB"], "negate": true}
  }
}'

# Fast-growing private US companies that recently raised funding
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "business",
  "filters": {
    "country_code": {"values": ["US"]},
    "company_age": {"values": ["3-6"]},
    "is_public_company": false,
    "events": {"values": ["new_funding_round"], "last_occurrence": 60}
  }
}'

# Buying intent: companies looking to buy HR software
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"business_intent_topics":{"topics":["HR:HR Software"]}}}'

# Paginate results
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"country_code":{"values":["US"]}},"size":100,"page_size":10,"page":2}'
```

If you need more than 50 records, fetch multiple pages explicitly. Do not assume one call returns the full dataset.

## `fetch-businesses-events`

Requires business IDs. Use after `fetch-entities` with `"entity_type":"business"` and an `events` filter to get full event records.

```bash
# Funding events for the last year
npx @vibeprospecting/vpai@latest fetch-businesses-events --args '{
  "business_ids": ["biz_abc123"],
  "event_types": ["new_funding_round"],
  "timestamp_from": "2024-01-01"
}'

# Typical workflow:
# 1. Find companies with recent events:
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"events":{"values":["new_funding_round"],"last_occurrence":60}}}'
# 2. Get event details for those companies:
npx @vibeprospecting/vpai@latest fetch-businesses-events --args '{"business_ids":["biz_abc123"],"event_types":["new_funding_round"],"timestamp_from":"2024-10-01"}'
```

## `fetch-entities` for prospects

```bash
# C-suite engineering leaders at US mid-size companies
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospect",
  "filters": {
    "job_level": {"values": ["c-suite"]},
    "job_department": {"values": ["engineering"]},
    "company_country_code": {"values": ["US"]},
    "company_size": {"values": ["201-500"]}
  }
}'

# Sales directors at SaaS companies in UK
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospect",
  "filters": {
    "job_level": {"values": ["director"]},
    "job_department": {"values": ["sales"]},
    "company_country_code": {"values": ["GB"]},
    "linkedin_category": {"values": ["Software Development"]}
  }
}'

# Marketing VPs with verified email at mid-revenue companies
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospect",
  "filters": {
    "job_level": {"values": ["vice president"]},
    "job_department": {"values": ["marketing"]},
    "company_revenue": {"values": ["10M-25M"]},
    "has_email": true
  }
}'

# Engineers new to their role (6-24 months)
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"prospect","filters":{"job_department":{"values":["engineering"]},"current_role_months":{"gte":6,"lte":24}}}'

# All senior people at a specific company
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"prospect","filters":{"business_id":{"values":["biz_abc123"]},"job_level":{"values":["director","vice president","c-suite"]}}}'
```

## `fetch-prospects-events`

```bash
# Job changes for specific prospects
npx @vibeprospecting/vpai@latest fetch-prospects-events --args '{"prospect_ids":["pro_xyz789"],"event_types":["new_job"],"timestamp_from":"2024-07-01"}'
```

## `web-search`

Use for news, press releases, and context not in Vibe Prospecting data. Prefer dedicated tools for company/person lookups.

```bash
npx @vibeprospecting/vpai@latest web-search --args '{"query":"Acme Corp Series B funding 2024"}'
```
