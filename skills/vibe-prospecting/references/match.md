# Match

Use match commands when you know the entity already and need canonical IDs for follow-up enrichment or event fetches.

Optional **`session_id`** in `--args` when this match is part of the same user task as a prior tool; pass the id returned in that tool’s JSON.

Add `--save-csv` when you want the returned `matched_businesses[]` or `matched_prospects[]` rows written to a CSV file. The CLI will return JSON with the CSV path and column list.

## `match-business`

Returns business IDs required by `enrich-business` and `fetch-businesses-events`. Not needed if you already ran `fetch-entities` with `"entity_type":"business"` because those results include IDs.

```bash
# By name + domain (most accurate)
npx @vibeprospecting/vpai@latest match-business --args '{"businesses_to_match":[{"name":"Salesforce","domain":"salesforce.com"}]}'

# Multiple at once
npx @vibeprospecting/vpai@latest match-business --args '{"businesses_to_match":[{"domain":"stripe.com"},{"name":"OpenAI"},{"name":"HubSpot","domain":"hubspot.com"}]}'
```

## `match-prospects`

Returns prospect IDs for `enrich-prospects` and `fetch-prospects-events`. Not needed if you already ran `fetch-entities` with `"entity_type":"prospect"`.

```bash
# By email (most reliable)
npx @vibeprospecting/vpai@latest match-prospects --args '{"prospects_to_match":[{"email":"jane.smith@acme.com"}]}'

# By LinkedIn URL
npx @vibeprospecting/vpai@latest match-prospects --args '{"prospects_to_match":[{"linkedin":"https://linkedin.com/in/janesmith"}]}'

# By name + company
npx @vibeprospecting/vpai@latest match-prospects --args '{"prospects_to_match":[{"full_name":"Jane Smith","company_name":"Acme Corp"}]}'

# Multiple at once
npx @vibeprospecting/vpai@latest match-prospects --args '{"prospects_to_match":[{"email":"alice@co.com"},{"full_name":"Bob Jones","company_name":"Acme"}]}'
```
