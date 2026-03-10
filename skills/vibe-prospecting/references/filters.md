# Filters Reference

All filters are passed as JSON to `--filters`.

## Shape

```json
{
  "filter_name": {
    "values": ["value1", "value2"],
    "negate": false
  }
}
```

Range-style filters use `gte` / `lte`.

## Autocomplete-first fields

Run `autocomplete` before using these directly in filters:

- `linkedin_category`
- `naics_category`
- `job_title`
- `business_intent_topics`
- `company_tech_stack_tech`
- `city_region`
- `city_region_country`

## Important constraints

- Do not combine `linkedin_category` with `naics_category`.
- Do not combine `job_title` with `job_level` or `job_department`.
- Do not combine country filters with region-country filters for the same entity type.
- Keep `events.last_occurrence` within the backend-supported range.

## Common enum-style filters

- `company_size`
- `company_revenue`
- `number_of_locations`
- `company_age`
- `job_level`
- `job_department`

## Common boolean filters

- `has_website`
- `is_public_company`
- `has_email`
- `has_phone_number`

## Event filters

- `events` filters are currently supported for `businesses` fetch workflows.
- Do not assume the same fetch filter works for `prospects`; use the dedicated `prospects events` command on fetched prospect ids instead.

## Examples

### Businesses

```json
{
  "linkedin_category": { "values": ["Software Development"] },
  "company_size": { "values": ["51-200", "201-500"] }
}
```

### Prospects

```json
{
  "job_title": { "values": ["Chief Technology Officer"] },
  "has_email": { "value": true }
}
```

### Event-filtered businesses

```json
{
  "events": {
    "values": ["new_funding_round"],
    "last_occurrence": 60,
    "negate": false
  }
}
```
