---
name: generate-list
description: "ICP-to-list pipeline. Describe your ideal customer in plain English and get a sized, previewed, and exportable list of matching businesses or prospects."
user-invocable: true
argument-hint: [describe your ideal customer — industry, size, role, location, tech stack]
---

# Generate List

Go from a plain-English ICP to a ready-to-export lead list using autocomplete → stats → fetch. The user describes their target via "$ARGUMENTS".

## Examples

- `/vibeprospecting-plugin:generate-list Series B SaaS companies in the US, 51-200 employees`
- `/vibeprospecting-plugin:generate-list VP of Sales at fintech companies, 201-500 employees`
- `/vibeprospecting-plugin:generate-list CTOs at companies using Kubernetes, New York`
- `/vibeprospecting-plugin:generate-list e-commerce companies in Europe with 10M-75M revenue`
- `/vibeprospecting-plugin:generate-list directors of engineering with verified email at Series A+ startups`

## Step 0 — Auth

Call the `get-auth-token` tool on the `explorium-mcp` MCP server. Extract `api_key` from the JSON response and export it:

```bash
export VP_API_KEY="<api_key>"
CLI="skills/vibe-prospecting/scripts/vibep.js"
```

## Step 1 — Classify Entity Type

From "$ARGUMENTS", determine whether the user wants:

- **Businesses** — companies, accounts, organisations (no person role mentioned)
- **Prospects** — people, contacts, leads, decision-makers (job title or role mentioned)

If unclear, ask one question: *"Are you looking for companies or for specific people at those companies?"*

## Step 2 — Parse ICP into Filters

Extract structured filter values from the natural language description:

**Shared filters:**
- Geography → `country_code` / `city_region_country` (need autocomplete)
- Company size → `company_size` (exact values: `1-10`, `11-50`, `51-200`, `201-500`, `501-1000`, `1001-5000`, `5001-10000`, `10001+`)
- Revenue range → `company_revenue`
- Tech stack → `company_tech_stack_tech` / `company_tech_stack_categories` (need autocomplete)
- Intent topics → `business_intent_topics` (need autocomplete)

**Business-only filters:**
- Industry → `linkedin_category` or `google_category` (always need autocomplete)
- NAICS → `naics_category` (need autocomplete)

**Prospect-only filters:**
- Job title → `job_title` (need autocomplete)
- Seniority → `job_level` (exact values: `cxo`, `vp`, `director`, `manager`, `senior`, `entry`, `owner`, `partner`)
- Department → `job_department` (exact values: `engineering`, `sales`, `marketing`, `finance`, `product`, `c-suite`, `data`, `human resources`, `operations`, etc.)
- Convenience flags → `--has-email`, `--has-phone`

## Step 3 — Resolve Autocomplete Filters

For every filter in the "need autocomplete" list, run autocomplete before building the final filter set. Always use `--semantic` for best matching:

```bash
AUTO=$(mktemp /tmp/vibep-auto.XXXXXX.json)

node "$CLI" businesses autocomplete linkedin_category "software development" --semantic \
  --call-reasoning "$QUERY" > "$AUTO"

node "$CLI" prospects autocomplete job_title "head of engineering" --semantic \
  --call-reasoning "$QUERY" > "$AUTO"
```

Extract the exact `value` strings from the response and use them verbatim in filters. Never guess or paraphrase autocomplete values.

## Step 4 — Size the Market (Free)

Run `stats` before any fetch. This is always free and prevents unexpected large fetches:

```bash
node "$CLI" businesses stats \
  --filters '{"linkedin_category":{"values":["Software Development"]},"company_size":{"values":["51-200","201-500"]}}' \
  --call-reasoning "$QUERY"

node "$CLI" prospects stats \
  --filter job_level=vp,director \
  --filter company_size=51-200 \
  --has-email \
  --call-reasoning "$QUERY"
```

Show the user the total result count. If the count is very large (>10,000), suggest narrowing the filters before fetching.

## Step 5 — Preview a Sample

Fetch 10 rows in preview mode to show the data shape before committing to a larger pull:

```bash
PREVIEW=$(mktemp /tmp/vibep-preview.XXXXXX.json)

node "$CLI" businesses fetch \
  --filters @filters.json \
  --limit 10 \
  --mode preview \
  --call-reasoning "$QUERY" > "$PREVIEW"

node "$CLI" prospects fetch \
  --filter job_level=vp,director \
  --filter company_size=51-200 \
  --has-email \
  --limit 10 \
  --mode preview \
  --call-reasoning "$QUERY" > "$PREVIEW"
```

Present the sample as a table:

**Businesses:**

| # | Company | Industry | Size | Revenue | Location | Domain |
|---|---|---|---|---|---|---|

**Prospects:**

| # | Name | Title | Company | Size | Location | Has Email | Has Phone |
|---|---|---|---|---|---|---|---|

Then ask the user:
> *"Found [total] matching [businesses/prospects]. Showing 10 of those. How many would you like to fetch? Fetching uses credits. Suggest a limit or say 'all' for the full set."*

**Do not proceed to full fetch without explicit confirmation.**

## Step 6 — Full Fetch

Once the user confirms a volume, fetch the full set. For large requests, write to file to keep context clean:

```bash
RESULTS=$(mktemp /tmp/vibep-results.XXXXXX.json)

node "$CLI" businesses fetch \
  --filters @filters.json \
  --limit 500 \
  --call-reasoning "$QUERY" > "$RESULTS"

node "$CLI" prospects fetch \
  --filter job_level=vp,director \
  --filter company_size=51-200 \
  --has-email \
  --limit 500 \
  --call-reasoning "$QUERY" > "$RESULTS"
```

Inspect only metadata back into context to confirm the fetch completed:

```bash
node -e "
const d = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
console.log('total_results:', d.meta.total_results);
console.log('returned:', d.data.length);
console.log('sample:', JSON.stringify(d.data.slice(0,2), null, 2));
" "$RESULTS"
```

## Step 7 — Present Summary

Show a brief summary of the completed fetch:

---

**List generated: [ICP summary]**

| Field | Value |
|---|---|
| Entity type | Businesses / Prospects |
| Filters applied | [comma-separated] |
| Total in market | [stats result] |
| Records fetched | [count] |
| Saved to | `$RESULTS` |

---

## Step 8 — Offer Next Actions

Ask the user:

1. **Export to CSV** — Re-run with `--to-file results.csv` or convert the JSON file
2. **Research specific items** — Run `/vibeprospecting-plugin:research` on selected rows for deep dossiers
3. **Enrich the list** — Run `enrich` on the results for firmographics, tech stack, contacts, or intent signals
4. **Fetch events** — Run `events` on the results to surface trigger signals (funding, hiring, role changes)
5. **Refine filters** — Adjust the ICP and re-run stats + fetch
