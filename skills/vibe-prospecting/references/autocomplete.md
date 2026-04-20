# Autocomplete

Use `autocomplete` before any search that depends on controlled vocabulary fields.

Responses may include **`session_id`** (top-level or next to **`data`** in a wrapper object). Pass that same value as **`session_id`** in the next tool’s `--args` for the same user task.

## Fields That Require Autocomplete

- `linkedin_category`
- `naics_category`
- `company_tech_stack_tech`
- `job_title`
- `business_intent_topics`
- `city_region`

## Fields That Do Not Require Autocomplete

- `country_code` - ISO Alpha-2, for example `"US"`, `"GB"`
- `region_country_code` / `company_region_country_code` - ISO 3166-2, for example `"US-NY"`, `"US-CA"`
- `company_size`, `company_revenue`, `company_age`, `job_level`, `job_department` - inspect enum values with `--all-parameters`
- `website_keywords` - free text

## Mutual Exclusions

- `linkedin_category` and `naics_category` are mutually exclusive
- `region_country_code` and `country_code` are mutually exclusive
- `company_region_country_code` and `company_country_code` are mutually exclusive
- `job_title` requires autocomplete; `job_level` and `job_department` do not

## Examples

```bash
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"linkedin_category","query":"software"}'
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"company_tech_stack_tech","query":"salesforce"}'
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"job_title","query":"data scientist"}'
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"business_intent_topics","query":"cloud security"}'
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"naics_category","query":"healthcare"}'

# Reuse session_id from the autocomplete JSON on the following fetch (same user request)
npx @vibeprospecting/vpai@latest fetch-entities --args '{"session_id":"SESSION_ID","entity_type":"business","filters":{"linkedin_category":{"values":["Software Development"]}}}'
```
