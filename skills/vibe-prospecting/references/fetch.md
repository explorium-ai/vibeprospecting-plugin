# Fetch

Use fetch commands to search for businesses or prospects, retrieve event details, or run general web search.

In cowork mode, use `fetch-entities` for both business and prospect search. Set `entity_type` to `businesses` or `prospects`.

Optional **`session_id`** in `--args`: reuse the value from the previous tool in the same user task when chaining after autocomplete, match, or an earlier fetch.

Add `--save-csv` when you want the returned `data[]` rows written to a CSV file. The CLI will return JSON with the CSV path and column list.

Before any `--save-csv` call, set `TMPDIR` to a writable sandbox path, for example `TMPDIR=/sessions/<id>/tmp-vpai`, then `mkdir -p "$TMPDIR"`.

## File-First Pattern

Do not paste raw JSON payloads into chat. Capture them to a file, then extract only the fields you need.

```bash
npx @vibeprospecting/vpai@latest fetch-entities --args '<json>' > /tmp/resp.json 2>&1
python3 -c 'import json; d=json.load(open("/tmp/resp.json")); print(d.get("page", {}).get("next_cursor"))'
```

If you use `--save-csv`, the CSV metadata response also preserves pagination metadata: it passes through `next_cursor` when present, or `page` when the tool paginates without a cursor.

## `fetch-entities` for businesses

```bash
# US software companies with 51-200 employees
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "businesses",
  "filters": {
    "country_code": {"values": ["US"]},
    "company_size": {"values": ["51-200"]},
    "linkedin_category": {"values": ["Software Development"]}
  }
}'

# Companies using Salesforce, excluding UK
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "businesses",
  "filters": {
    "company_tech_stack_tech": {"values": ["Salesforce"]},
    "country_code": {"values": ["GB"], "negate": true}
  }
}'

# Fast-growing private US companies that recently raised funding
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "businesses",
  "filters": {
    "country_code": {"values": ["US"]},
    "company_age": {"values": ["3-6"]},
    "is_public_company": false,
    "events": {"values": ["new_funding_round"], "last_occurrence": 60}
  }
}'

# Buying intent: companies looking to buy HR software
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"business_intent_topics":{"topics":["HR:HR Software"]}}}'

# Paginate results
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"country_code":{"values":["US"]}},"size":100,"page_size":10,"page":2}'
```

If you need more than 50 records, fetch multiple pages explicitly. Do not assume one call returns the full dataset.

## Job Filter Rules

- `job_title` is substring-match, not exact-match.
- For executive searches, always combine `job_title` with `job_level`, usually `c-suite`, to remove assistants, advisors, and office-of roles.

```bash
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospects",
  "filters": {
    "job_title": {"values": ["chief executive officer"]},
    "job_level": {"values": ["c-suite"]},
    "company_country_code": {"values": ["US"]}
  }
}'
```

## Company Size Pitfall

`company_size` uses fixed buckets such as `1-10`, `11-50`, `51-200`, `201-500`, and higher. There is no exact `>100` cutoff. For requests like "over 100 employees", either:

- approximate with adjacent buckets such as `51-200` and `201-500`, or
- enrich matched businesses with firmographics if exact headcount matters.

## `fetch-businesses-events`

Requires business IDs. Use after `fetch-entities` with `"entity_type":"businesses"` and an `events` filter to get full event records.

```bash
# Funding events for the last year
npx @vibeprospecting/vpai@latest fetch-businesses-events --args '{
  "business_ids": ["biz_abc123"],
  "event_types": ["new_funding_round"],
  "timestamp_from": "2024-01-01"
}'

# Typical workflow:
# 1. Find companies with recent events:
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"events":{"values":["new_funding_round"],"last_occurrence":60}}}'
# 2. Get event details for those companies:
npx @vibeprospecting/vpai@latest fetch-businesses-events --args '{"business_ids":["biz_abc123"],"event_types":["new_funding_round"],"timestamp_from":"2024-10-01"}'
```

## `fetch-entities` for prospects

```bash
# C-suite engineering leaders at US mid-size companies
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospects",
  "filters": {
    "job_level": {"values": ["c-suite"]},
    "job_department": {"values": ["engineering"]},
    "company_country_code": {"values": ["US"]},
    "company_size": {"values": ["201-500"]}
  }
}'

# Sales directors at SaaS companies in UK
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospects",
  "filters": {
    "job_level": {"values": ["director"]},
    "job_department": {"values": ["sales"]},
    "company_country_code": {"values": ["GB"]},
    "linkedin_category": {"values": ["Software Development"]}
  }
}'

# Marketing VPs with verified email at mid-revenue companies
npx @vibeprospecting/vpai@latest fetch-entities --args '{
  "entity_type": "prospects",
  "filters": {
    "job_level": {"values": ["vice president"]},
    "job_department": {"values": ["marketing"]},
    "company_revenue": {"values": ["10M-25M"]},
    "has_email": true
  }
}'

# Engineers new to their role (6-24 months)
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"prospects","filters":{"job_department":{"values":["engineering"]},"current_role_months":{"gte":6,"lte":24}}}'

# All senior people at a specific company
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"prospects","filters":{"business_id":{"values":["biz_abc123"]},"job_level":{"values":["director","vice president","c-suite"]}}}'
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
