# Fetch Stats

Use statistics commands when you need counts and breakdowns without fetching individual records.

In cowork mode, use `fetch-entities-statistics` for both business and prospect counts. Set `entity_type` to `business` or `prospect`.

## `fetch-entities-statistics` for businesses

Returns total counts and market sizing summaries for company searches.

```bash
# How many US SaaS companies with 51-200 employees?
npx @vibeprospecting/vpai@latest fetch-entities-statistics --args '{"entity_type":"business","filters":{"country_code":{"values":["US"]},"company_size":{"values":["51-200"]},"linkedin_category":{"values":["Software Development"]}}}'

# Fintech market size across Europe
npx @vibeprospecting/vpai@latest fetch-entities-statistics --args '{"entity_type":"business","filters":{"linkedin_category":{"values":["Financial Services"]},"country_code":{"values":["GB","DE","FR","NL","SE"]}}}'
```

## `fetch-entities-statistics` for prospects

Returns total counts and breakdowns for prospect searches.

```bash
# Department breakdown of engineers at US companies
npx @vibeprospecting/vpai@latest fetch-entities-statistics --args '{"entity_type":"prospect","filters":{"job_department":{"values":["engineering"]},"company_country_code":{"values":["US"]}}}'

# How many marketing directors in fintech globally?
npx @vibeprospecting/vpai@latest fetch-entities-statistics --args '{"entity_type":"prospect","filters":{"job_level":{"values":["director"]},"job_department":{"values":["marketing"]},"linkedin_category":{"values":["Financial Services"]}}}'
```
