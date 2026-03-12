# Filters Reference

Use filters in one of two ways:

- repeatable `--filter key=value1,value2` flags for common text and enum filters
- raw `--filters <json-or-@source>` when you need the backend shape directly

Prospect commands also expose convenience flags:

- `--has-email`
- `--has-phone`

## Raw JSON shape

```json
{
  "filter_name": {
    "values": ["value1", "value2"],
    "negate": false
  }
}
```

## Autocomplete-first fields

Run `autocomplete` before using these directly in filters:

- `country`
- `country_code`
- `region_country_code`
- `company_name`
- `city_region_country`
- `city_region`
- `company_tech_stack_tech`
- `company_tech_stack_categories`
- `company_size`
- `company_revenue`
- `number_of_locations`
- `company_age`
- `job_department`
- `job_level`
- `business_intent_topics`
- `google_category`
- `linkedin_category`
- `naics_category`
- `job_title`

## Shared filters

- `country`
- `country_code`
- `region_country_code`
- `company_name` (autocomplete)
- `city_region_country` (autocomplete)
- `city_region` (autocomplete)
- `company_size`: `1-10`, `11-50`, `51-200`, `201-500`, `501-1000`, `1001-5000`, `5001-10000`, `10001+`
- `company_revenue`: `0-500K`, `500K-1M`, `1M-5M`, `5M-10M`, `10M-25M`, `25M-75M`, `75M-200M`, `200M-500M`, `500M-1B`, `1B-10B`, `10B-100B`, `100B-1T`, `1T-10T`, `10T+`
- `company_tech_stack_tech` (autocomplete)
- `company_tech_stack_categories` (autocomplete)
- `business_intent_topics` (autocomplete)

## Business-only filters

- `naics_category` (autocomplete)
- `google_category` (autocomplete)
- `linkedin_category` (autocomplete)
- `number_of_locations`
- `company_age`

## Prospect-only filters

- `job_title` (autocomplete)
- `job_level`: `cxo`, `vp`, `director`, `manager`, `senior`, `entry`, `training`, `owner`, `partner`, `unpaid`
- `job_department`: `engineering`, `sales`, `marketing`, `finance`, `product`, `c-suite`, `data`, `human resources`, `operations`, `legal`, `customer success`, `it`, `consulting`, `r&d`, `logistics`, `manufacturing`, `medical`, `real estate`, `media`
- `has_email`
- `has_phone`

## Examples

### Repeated `--filter`

```bash
node "$CLI" businesses stats --filter country=US --filter company_size=51-200 --call-reasoning "$QUERY"
node "$CLI" prospects fetch --filter job_level=director,vp --filter company_size=201-500 --has-email --limit 10 --mode preview --call-reasoning "$QUERY"
```

### Raw JSON

```json
{
  "linkedin_category": { "values": ["Software Development"] },
  "company_size": { "values": ["51-200", "201-500"] }
}
```
