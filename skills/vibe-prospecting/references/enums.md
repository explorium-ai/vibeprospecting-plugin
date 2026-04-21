# Enums

Use this file as the first stop for fixed enum-style filters that do not require autocomplete.

If a value is missing here or the tool rejects the payload, verify the live schema with `--all-parameters --json`.

## Common Fixed Enums

- `entity_type`: `businesses`, `prospects`
- `events`: use schema-backed event values such as `new_funding_round`, `new_job`, and other event types from the live schema

## Company Size

Filter key: `company_size`

Values:

- `1-10`
- `11-50`
- `51-200`
- `201-500`
- `501-1000`
- `1001-5000`
- `5001-10000`
- `10001+`

Related output field: `number_of_employees_range`

## Company Age

Filter key: `company_age`

Values:

- `0-3`
- `3-6`
- `6-10`
- `10-20`
- `20+`

## Revenue

Filter key: `company_revenue`

Values:

- `0-500K`
- `500K-1M`
- `1M-5M`
- `5M-10M`
- `10M-25M`
- `25M-75M`
- `75M-200M`
- `200M-500M`
- `500M-1B`
- `1B-10B`
- `10B-100B`
- `100B-1T`
- `1T-10T`
- `10T+`

Related output field: `yearly_revenue_range`

Example: to approximate `$10B+`, use:

```json
{
  "company_revenue": {
    "values": ["10B-100B", "100B-1T", "1T-10T", "10T+"]
  }
}
```

## Job Level

Filter key: `job_level`

Values:

- `c-suite`
- `manager`
- `owner`
- `senior non-managerial`
- `partner`
- `freelancer`
- `junior`
- `director`
- `board member`
- `founder`
- `president`
- `senior manager`
- `advisor`
- `non-managerial`
- `vice president`

## Job Department

Filter key: `job_department`

Values:

- `administration`
- `healthcare`
- `partnerships`
- `c-suite`
- `design`
- `human resources`
- `engineering`
- `education`
- `strategy`
- `product`
- `sales`
- `r&d`
- `retail`
- `customer success`
- `security`
- `public service`
- `creative`
- `it`
- `support`
- `marketing`
- `trade`
- `legal`
- `operations`
- `real estate`
- `procurement`
- `data`
- `manufacturing`
- `logistics`
- `finance`

## Notes

- `linkedin_category`, `naics_category`, `company_tech_stack_tech`, `job_title`, `business_intent_topics`, and `city_region` require `autocomplete`.
- `company_size` uses fixed buckets. There is no exact `>100 employees` enum.
- `job_title` is substring-match. Combine with `job_level` when precision matters.
- Use the filter names in requests (`company_size`, `company_revenue`). Output fields may use different names such as `number_of_employees_range` and `yearly_revenue_range`.
