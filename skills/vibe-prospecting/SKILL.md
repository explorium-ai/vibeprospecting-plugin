---
name: vibe-prospecting
description: This skill should be used when the user wants to search for businesses or prospects in Explorium, autocomplete filters, preview a target market, enrich matched records, inspect business or prospect events, or chain results through local JSON file workflows.
---

# Vibe Prospecting Skill

Use the vendored CLI at `skills/vibe-prospecting/scripts/vibep.js`.

## Runtime Contract

- Run the CLI with `node`, never through an install step:
  ```bash
  CLI="skills/vibe-prospecting/scripts/vibep.js"
  node "$CLI" --help
  ```
- Prefer `--json` for every CLI call made inside the skill.
- Redirect large `--json` outputs to files instead of printing them into the conversation.
- Use inline JSON only for small payloads. Use `@file` or `@-` for anything non-trivial.

## Auth

- Auth precedence is:
  1. `VP_API_KEY`
  2. `~/.config/vibeprospecting/config.json`
- Verify auth before starting a paid workflow:
  ```bash
  node "$CLI" auth status --json
  ```
- If auth is missing, ask the user for an Explorium API key and then either:
  ```bash
  export VP_API_KEY="your-key"
  ```
  or:
  ```bash
  node "$CLI" auth login --api-key "your-key"
  ```
- Mention that `VP_API_KEY` overrides stored config.

## File Workflow

- Generate a plan id at the start of each workflow:
  ```bash
  PLAN_ID=$(node -e "console.log(require('node:crypto').randomUUID())")
  ```
- For results that may exceed a few kilobytes, redirect JSON to a temp file:
  ```bash
  RESULT=$(mktemp /tmp/vibep-businesses.XXXXXX.json)
  node "$CLI" businesses fetch --filters @filters.json --limit 10 --json --plan-id "$PLAN_ID" --call-reasoning "$QUERY" > "$RESULT"
  ```
- Inspect only the fields needed for the next step:
  ```bash
  node -e "const fs=require('node:fs'); const d=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); console.log(d.meta.total_results); console.log(JSON.stringify(d.data.slice(0,3), null, 2));" "$RESULT"
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

- Fetch 5-10 rows first.
- Summarize the sample for the user.
- Do not proceed to high-volume fetch, enrich, or events without explicit confirmation.

### 5. Use file chaining for follow-up operations

- Feed previous JSON output back into later commands with `--input @file.json`.
- Use `enrich` only on records that already contain `business_id` or `prospect_id`.
- Use `events` only after ids exist.

### 6. Keep large payloads out of chat context

- Redirect `--json` output to files.
- Read only targeted metadata or small previews back into context.

## Examples

### Autocomplete then stats

```bash
AUTO=$(mktemp /tmp/vibep-auto.XXXXXX.json)
node "$CLI" businesses autocomplete --field linkedin_category --query "software" --semantic --json > "$AUTO"
node "$CLI" businesses stats --filters '{"linkedin_category":{"values":["Software Development"]}}' --json
```

### Preview businesses

```bash
FETCH=$(mktemp /tmp/vibep-businesses.XXXXXX.json)
node "$CLI" businesses fetch --filters @filters.json --limit 10 --json > "$FETCH"
```

### Enrich previous results

```bash
ENRICHED=$(mktemp /tmp/vibep-enriched.XXXXXX.json)
node "$CLI" businesses enrich --input "@$FETCH" --enrichments firmographics,technographics --json > "$ENRICHED"
```

### Fetch prospect events

```bash
EVENTS=$(mktemp /tmp/vibep-prospect-events.XXXXXX.json)
node "$CLI" prospects events --input @prospects.json --event-types prospect_changed_company,prospect_changed_role --json > "$EVENTS"
```

## References

- Use `references/filters.md` for filter structure, autocomplete-only fields, and common constraints.
- Use `references/enrichments.md` for supported enrichment names and parameter notes.
- Use `references/events.md` for supported business and prospect event types.
