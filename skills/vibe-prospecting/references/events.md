# Events Reference

Use `events` only on rows that already contain ids.

- `businesses events` requires `business_id`
- `prospects events` requires `prospect_id`
- Optional time filters: `--since YYYY-MM-DD` and `--until YYYY-MM-DD`
- Use `--input @file.json` for prior JSON output, or `--from-file` / `--to-file` for CSV and JSON files

## Business events

- `new_funding_round`
- `ipo_announcement`
- `new_investment`
- `new_product`
- `new_office`
- `new_partnership`
- `company_award`
- `increase_in_engineering_department`
- `increase_in_sales_department`
- `increase_in_marketing_department`
- `increase_in_all_departments`
- `hiring_in_engineering_department`
- `hiring_in_sales_department`
- `hiring_in_marketing_department`
- `employee_joined_company`
- `decrease_in_engineering_department`
- `decrease_in_sales_department`
- `decrease_in_all_departments`
- `closing_office`
- `cost_cutting`
- `merger_and_acquisitions`
- `lawsuits_and_legal_issues`
- `outages_and_security_breaches`

Additional hiring events supported by the CLI:

- `hiring_in_creative_department`
- `hiring_in_education_department`
- `hiring_in_finance_department`
- `hiring_in_health_department`
- `hiring_in_human_resources_department`
- `hiring_in_legal_department`
- `hiring_in_operations_department`
- `hiring_in_professional_service_department`
- `hiring_in_support_department`
- `hiring_in_trade_department`
- `hiring_in_unknown_department`

Additional department movement events supported by the CLI:

- `increase_in_operations_department`
- `increase_in_customer_service_department`
- `decrease_in_marketing_department`
- `decrease_in_operations_department`
- `decrease_in_customer_service_department`

## Prospect events

- `prospect_changed_role`
- `prospect_changed_company`
- `prospect_job_start_anniversary`

## Examples

```bash
node "$CLI" businesses events --input @businesses.json --event-types new_funding_round,new_partnership --since 2025-01-01 --call-reasoning "$QUERY" > /tmp/business-events.json
node "$CLI" prospects events --input @prospects.json --event-types prospect_changed_company --call-reasoning "$QUERY" > /tmp/prospect-events.json
```
