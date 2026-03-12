---
name: research
description: "Deep-research a business or person. Drop names, domains, emails, or LinkedIn URLs and get a full dossier: matched Explorium ID, enriched firmographics/contacts, and recent trigger events."
user-invocable: true
argument-hint: [company names, domains, emails, LinkedIn URLs, or person names + company]
---

# Research

Turn raw identifiers into a full intelligence dossier using match → enrich → events. The user provides one or more targets via "$ARGUMENTS".

## Examples

- `/vibeprospecting-plugin:research Salesforce`
- `/vibeprospecting-plugin:research stripe.com, notion.so, figma.com`
- `/vibeprospecting-plugin:research John Smith at Acme Corp`
- `/vibeprospecting-plugin:research sarah@stripe.com`
- `/vibeprospecting-plugin:research https://www.linkedin.com/in/jeffweiner08`
- `/vibeprospecting-plugin:research leads.csv` (CSV file with company names/domains or prospect names/emails)

## Step 0 — Auth

Call the `get-auth-token` tool on the `explorium-mcp` MCP server. Extract `api_key` from the JSON response and export it:

```bash
export VP_API_KEY="<api_key>"
CLI="skills/vibe-prospecting/scripts/vibep.js"
```

## Step 1 — Classify Targets

From "$ARGUMENTS", determine entity type and extract identifiers:

**Business targets** — when input looks like company names, domains, or URLs:
- Extract `name` (company name) and/or `domain` (domain or full URL stripped to domain)
- Build a JSON array: `[{"name": "Salesforce", "domain": "salesforce.com"}, ...]`

**Prospect targets** — when input looks like people (name + company, email, LinkedIn URL, phone):
- Extract `full_name`, `company_name`, `email`, `phone_number`, `linkedin`
- Build a JSON array: `[{"full_name": "John Smith", "company_name": "Acme"}, ...]`

**CSV/JSON file input** — when the argument is a file path, pass it directly to `--from-file`. Ask the user for the column mapping if it isn't obvious.

If the entity type is ambiguous, ask the user one clarifying question before continuing.

## Step 2 — Match to Explorium IDs

Write the identifiers to a temp file and run `match`:

```bash
MATCH_OUT=$(mktemp /tmp/vibep-match.XXXXXX.json)

# For businesses (inline JSON)
node "$CLI" businesses match \
  --businesses '[{"name":"Salesforce","domain":"salesforce.com"}]' \
  --call-reasoning "$QUERY" > "$MATCH_OUT"

# For businesses (from file)
node "$CLI" businesses match \
  --from-file leads.csv \
  --column-map '{"Company":"name","Website":"domain"}' \
  --to-file "$MATCH_OUT" \
  --call-reasoning "$QUERY"

# For prospects (inline JSON)
node "$CLI" prospects match \
  --prospects '[{"full_name":"John Smith","company_name":"Acme","email":"john@acme.com"}]' \
  --call-reasoning "$QUERY" > "$MATCH_OUT"

# For prospects (from file)
node "$CLI" prospects match \
  --from-file leads.csv \
  --column-map '{"Name":"full_name","Company":"company_name","Email":"email","LinkedIn":"linkedin"}' \
  --to-file "$MATCH_OUT" \
  --call-reasoning "$QUERY"
```

Inspect match results and surface any unmatched rows to the user now. Only proceed with matched rows (those containing `business_id` or `prospect_id`).

## Step 3 — Enrich

Run enrich on the matched output, selecting enrichments appropriate to the entity type:

```bash
ENRICH_OUT=$(mktemp /tmp/vibep-enrich.XXXXXX.json)

# Businesses — firmographics + funding + tech stack + intent signals
node "$CLI" businesses enrich \
  --input "@$MATCH_OUT" \
  --enrichments firmographics,technographics,funding_and_acquisition,website_traffic,bombora_intent \
  --call-reasoning "$QUERY" > "$ENRICH_OUT"

# Prospects — contact info + social profiles
node "$CLI" prospects enrich \
  --input "@$MATCH_OUT" \
  --enrichments contacts_information,profiles \
  --call-reasoning "$QUERY" > "$ENRICH_OUT"
```

If the matched set contains both businesses and prospects, run enrich for each entity type separately and merge for presentation.

## Step 4 — Fetch Trigger Events

Fetch recent events for each matched entity (last 90 days by default):

```bash
EVENTS_OUT=$(mktemp /tmp/vibep-events.XXXXXX.json)
SINCE=$(date -v-90d +%Y-%m-%d 2>/dev/null || date -d '90 days ago' +%Y-%m-%d)

# Businesses
node "$CLI" businesses events \
  --input "@$MATCH_OUT" \
  --event-types new_funding_round,new_partnership,new_product,hiring_in_engineering_department,hiring_in_sales_department,increase_in_all_departments,merger_and_acquisitions \
  --since "$SINCE" \
  --call-reasoning "$QUERY" > "$EVENTS_OUT"

# Prospects
node "$CLI" prospects events \
  --input "@$MATCH_OUT" \
  --event-types prospect_changed_role,prospect_changed_company,prospect_job_start_anniversary \
  --since "$SINCE" \
  --call-reasoning "$QUERY" > "$EVENTS_OUT"
```

## Step 5 — Present the Dossier

For each successfully matched target, present one card:

---

### [Company Name / Full Name] · [Match confidence if available]

**[Title]** · [Company] · [Industry] · [Employee range] employees

| Field | Detail |
|---|---|
| Explorium ID | `business_id` or `prospect_id` |
| Domain / LinkedIn | ... |
| Revenue | ... |
| Funding | Total raised, last round |
| Tech Stack | Top tools |
| Bombora Intent | Topics + score |
| Website Traffic | Monthly visits + trend |
| Work Email | ... |
| Direct Phone | ... |

**Recent trigger events (last 90 days):**

| Date | Event | Detail |
|---|---|---|

---

For unmatched rows, show a brief "No Explorium record found" note.

## Step 6 — Offer Next Actions

Ask the user which action to take:

1. **Generate a list** — Pivot to `/vibeprospecting-plugin:generate-list` using this research as ICP context
2. **Expand research** — Run deeper enrichments (e.g. `workforce_trends`, `competitive_landscape`, `linkedin_posts`)
3. **Export to CSV** — Re-run enrich with `--to-file enriched.csv` to produce a downloadable file
4. **Research more targets** — Add more names/domains/emails to the current session
