# vibeprospecting-plugin

Plugin + skill for Explorium prospecting workflows, backed by a vendored `vibep` CLI bundle.

## Vendored CLI

Run the bundled CLI directly with Node:

```bash
node skills/vibe-prospecting/scripts/vibep.js --help
```

## What it covers

- autocomplete filter values before building paid queries
- run free `stats` calls before `fetch`
- fetch business or prospect previews and full result sets
- match raw CSV/JSON lead lists to Explorium ids
- enrich matched rows that already contain `business_id` or `prospect_id`
- fetch business or prospect events from previously matched/fetched ids

## Runtime notes

- no install step; always run the vendored bundle with `node`
- all commands emit minified JSON to stdout; errors go to stderr
- use `--to-file` for CSV/JSON exports, or shell redirection when you want the raw JSON envelope
- pass `--call-reasoning` on API-facing commands when the original user prompt is available

## Auth precedence

1. `VP_API_KEY`
2. `~/.config/vibeprospecting/config.json`

Optional override:

- `VP_BASE_URL`
