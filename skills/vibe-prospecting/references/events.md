# Events Reference

Use `events` only on JSON inputs that already contain ids.

## Business events

Common event types:

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

## Prospect events

- `prospect_changed_role`
- `prospect_changed_company`
- `prospect_job_start_anniversary`

## Examples

```bash
node "$CLI" businesses events --input @businesses.json --event-types new_funding_round,new_partnership --json > /tmp/business-events.json
node "$CLI" prospects events --input @prospects.json --event-types prospect_changed_company --json > /tmp/prospect-events.json
```
