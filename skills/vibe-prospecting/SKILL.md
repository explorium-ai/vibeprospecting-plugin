---
name: vibe-prospecting
description: Use this skill for Explorium prospecting workflows: autocomplete filters, run market stats, fetch business or prospect previews, match CSV/JSON lead lists, enrich matched ids, inspect events, and chain results through local files.
---

# Vibe Prospecting Skill

Use the vendored CLI at `skills/vibe-prospecting/scripts/vibep.js`.

## Runtime Contract

- Run the CLI with `node`, never through an install step:
  ```bash
  CLI="skills/vibe-prospecting/scripts/vibep.js"
  node "$CLI" --help
  ```
- All commands emit minified JSON to stdout. Errors go to stderr.
- Prefer `--to-file` for CSV or JSON exports. Use stdout redirection when you want the raw JSON envelope.
- Use inline JSON only for small payloads. Use `@file` or `@-` for anything non-trivial.
- On API-facing commands, pass `--call-reasoning "$QUERY"` with the user's original request wording, minus unrelated PII.

## Auth

**Always obtain the token from the MCP server first.** Do not ask the user for an API key unless the MCP call fails.

1. Call the `get-auth-token` tool on the `explorium-mcp` MCP server (no arguments required).
2. Extract the `api_key` field from the response.
3. Export it for the CLI session:
   ```bash
   export VP_API_KEY="<api_key from get-auth-token>"
   ```
4. All subsequent `node "$CLI" ...` commands in the same shell will use that key automatically.

### Fallback

If the MCP server is unreachable or returns an error:

- Auth precedence is:
  1. `VP_API_KEY` environment variable (already set by the user)
  2. `~/.config/vibeprospecting/config.json`
- Verify auth before starting a paid workflow:
  ```bash
  node "$CLI" auth status
  ```
- If auth is still missing, ask the user for an Explorium API key and then either:
  ```bash
  export VP_API_KEY="your-key"
  ```
  or:
  ```bash
  node "$CLI" auth login --api-key "your-key"
  ```
- `VP_API_KEY` always overrides stored config.

## File Workflow

- For results that may exceed a few kilobytes, write them to a temp file:
  ```bash
  RESULT=$(mktemp /tmp/vibep-businesses.XXXXXX.json)
  node "$CLI" businesses fetch --filters @filters.json --limit 10 --mode preview --call-reasoning "$QUERY" > "$RESULT"
  ```
- Inspect only the fields needed for the next step:
  ```bash
  node -e "const fs=require('node:fs'); const d=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); console.log(d.meta.total_results); console.log(JSON.stringify(d.data.slice(0,3), null, 2));" "$RESULT"
  ```
- Prefer `--from-file` and `--to-file` when the user already has CSV or JSON files:
  ```bash
  node "$CLI" businesses match --from-file leads.csv --to-file matched.csv
  ```

## Workflow

### 1. Determine entity type

- Use `businesses` for companies and accounts.
- Use `prospects` for people, contacts, leads, and decision makers.

### 2. Resolve autocomplete-dependent filters first

- For fields listed in `references/filters.md` as autocomplete-only, run autocomplete before stats or fetch.
- Use the exact returned values in subsequent filters.

### 3. Run free stats before spending credits

- Always run `stats` before large fetches.
- If the result set is very large, suggest narrowing before fetching.

### 4. Fetch a small preview first

- Fetch 5-10 rows first, usually with `--mode preview`.
- Summarize the sample for the user.
- Do not proceed to high-volume fetch, enrich, or events without explicit confirmation.

### 5. Use `match` for raw lead lists

- If the user starts from CRM exports, spreadsheets, or local JSON/CSV lists, run `match` first.
- `businesses match` expects identifiers like `name`, `domain`, `url`, or `linkedin_url`.
- `prospects match` expects either `full_name` + `company_name`, or `email`, or `phone_number`, or `linkedin`.

### 6. Use file chaining for follow-up operations

- Feed previous JSON output back into later commands with `--input @file.json` or `--input @-`.
- Use `enrich` only on records that already contain `business_id` or `prospect_id`.
- Use `events` only after ids exist.

### 7. Keep large payloads out of chat context

- Redirect stdout to files or use `--to-file`.
- Read only targeted metadata or small previews back into context.

## Examples

### Obtain token then run a workflow

First, call the `get-auth-token` MCP tool. Then use the returned `api_key`:

```bash
CLI="skills/vibe-prospecting/scripts/vibep.js"
export VP_API_KEY="<api_key from get-auth-token>"
```

### Autocomplete then stats

```bash
AUTO=$(mktemp /tmp/vibep-auto.XXXXXX.json)
node "$CLI" businesses autocomplete linkedin_category "software" --semantic --call-reasoning "$QUERY" > "$AUTO"
node "$CLI" businesses stats --filters '{"linkedin_category":{"values":["Software Development"]}}' --call-reasoning "$QUERY"
```

### Preview businesses

```bash
FETCH=$(mktemp /tmp/vibep-businesses.XXXXXX.json)
node "$CLI" businesses fetch --filters @filters.json --limit 10 --mode preview --call-reasoning "$QUERY" > "$FETCH"
```

### Match raw CSV leads

```bash
node "$CLI" prospects match --from-file leads.csv --column-map '{"Name":"full_name","Company":"company_name","Email":"email"}' --to-file matched.csv --call-reasoning "$QUERY"
```

### Enrich previous results

```bash
ENRICHED=$(mktemp /tmp/vibep-enriched.XXXXXX.json)
node "$CLI" businesses enrich --input "@$FETCH" --enrichments firmographics,technographics --call-reasoning "$QUERY" > "$ENRICHED"
```

### Fetch prospect events

```bash
EVENTS=$(mktemp /tmp/vibep-prospect-events.XXXXXX.json)
node "$CLI" prospects events --input @prospects.json --event-types prospect_changed_company,prospect_changed_role --since 2025-01-01 --call-reasoning "$QUERY" > "$EVENTS"
```

## References

- Use `references/filters.md` for filter structure, shared keys, and autocomplete-supported fields.
- Use `references/enrichments.md` for supported enrichment names and parameter notes.
- Use `references/events.md` for supported business and prospect event types.
- Use `references/mcp-auth.md` for the MCP token gateway details and response shape.
