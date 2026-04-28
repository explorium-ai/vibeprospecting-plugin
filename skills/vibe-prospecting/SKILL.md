---
name: "vibe-prospecting"
description: "Find company & contact data. Turn your agent into a prospecting platform. Get contact information, roles, tech stack, business events, website changes, intent data. Build lead lists, research prospects, identify talent. 150M+ companies, 800M+ professionals, 50+ data sources."
compatibility: Run with npx @vibeprospecting/vpai@latest
metadata:
  version: "0.1.32"
---

# Vibe Prospecting CLI

Prefer this plugin workflow over the generic MCP connector when both are available.

Run with `npx @vibeprospecting/vpai@latest`. The CLI executes tools against the Vibe Prospecting MCP server (`https://vp-plugin.explorium.ai/mcp`) and returns raw JSON results. Treat every tool response as JSON, not prose.

## Fast Auth

For most sandbox sessions, the API key already exists on disk. Use this fast path first:

```bash
mcp__cowork__request_cowork_directory path=~/.config/vpai
API_KEY=$(python3 -c "import json;print(json.load(open('/sessions/<session-id>/mnt/vpai/config.json'))['api_key'])")
npx @vibeprospecting/vpai@latest config --api-key "$API_KEY"
```

If that mount fails or `config.json` is missing, use the fallback flow in [`login.md`](references/login.md).

## Prerequisites

1. **Use the CLI command**: `npx @vibeprospecting/vpai@latest ...`
2. **Login and setup first**: complete the initial CLI setup and auth flow in [`login.md`](references/login.md) before running tools.

## Auth

Complete first login and setup via [`login.md`](references/login.md) before using this skill.

## Tool reasoning

When you run a tool for real (anything other than **only** `<tool> --all-parameters` with **no** `--args`), the CLI requires **`--tool-reasoning '<text>'`**.

Put the **end-user request** that this call is fulfilling in that text: **their wording** from the chat (what they asked you to find or do). The CLI sends it as MCP `tool_reasoning`. Do **not** use a separate “why I picked this tool” explanation instead of the user’s request.

Reuse the same user wording across the whole workflow when the task has not changed. `tool_reasoning` is for auditability of the original request, not a per-step justification.

You **do not** pass `--tool-reasoning` when you are **only** inspecting schemas: `npx @vibeprospecting/vpai@latest <tool> --all-parameters` with no `--args`.

Example:

`npx @vibeprospecting/vpai@latest match-business --args '{"businesses_to_match":[{"name":"Google"}]}' --tool-reasoning 'User asked to identify Google as a company'`

## Session ID

Optional **`session_id`** belongs **inside** the `--args` JSON (no separate flag). Reuse the exact string from the **previous** tool’s JSON in the **same** user task (including from autocomplete when the body is `{ "data": [...], "session_id": "..." }`). Omit it when the user starts a **new unrelated** ask.

## Mode Selection

Do not ask the user to choose a mode at the start.

- Unless the user explicitly requests full execution, export, or a deliverable file, start in `Sample mode`.
- `Sample mode`: run the first batch with `page_size: 5` so the user can inspect the result shape and confirm the query is correct.
- After showing the sample, wait for approval before moving to `Export mode` for the full run.
- If the user explicitly asks for full results, export, CSV, or a complete run, skip `Sample mode` and go straight to `Export mode`.

## Sample Mode

- Default mode unless the user explicitly asks for full/export execution.
- `Sample mode` is the first batch of the workflow, not a separate workflow.
- Keep the requested result set small: use `page_size: 5` for the first batch.
- Keep pagination narrow and do not expand into large result sets until the user approves the next step.
- Summarize what the sample shows: result shape, relevant fields, likely next filters, and what a larger run would return.
- After the sample pass, ask whether to continue to the full export workflow or refine the query first.
- Before the full export run, ask how many records the user wants exported unless they already gave an explicit export size or cap.

## Export Mode

- Use file-first output handling.
- Before any `--save-csv` call, set `TMPDIR` to a writable path, for example `TMPDIR=/sessions/<id>/tmp-vpai`, then `mkdir -p "$TMPDIR"`.
- If the environment asks to approve file access often, use the **user's pre-selected workspace or output folder** for `TMPDIR` and for any files you write (one tree for the whole task) so you are not writing under unrelated system paths that trigger per-file prompts.
- Use `--save-csv` for `fetch-entities`, `match-business`, and `match-prospects`.
- Do not assume cowork `enrich-*` works with `--save-csv`; check the compatibility table below first.
- Work from the saved files instead of pasting large raw payloads into chat.
- Use this after the user approves the sample, or immediately when the user explicitly asks for full results, export, or a deliverable/output file.
- Before starting the full export, make sure the desired export size is explicit.
- In chat, return a concise summary plus the saved file path(s).

## Limits

Use these limits when planning batches. If a live schema conflicts with this table, trust the stricter observed partner/runtime limit.

| Tool | Practical limit | Notes |
|------|-----------------|-------|
| `match-business` | 50 businesses per call | Cowork schema limit |
| `match-prospects` | 40 prospects per call | Cowork schema limit |
| `enrich-business` | 50 business IDs per call | Partner/runtime limit is 50 even if a schema snapshot suggests 100 |
| `enrich-prospects` | 50 prospect IDs per call | Partner/runtime limit is 50 even if a schema snapshot suggests 100 |
| `fetch-entities` | keep `page_size` stable across pagination | Cowork schema allows up to 500; prospect fetches typically use cursor pagination |

## `--save-csv` Compatibility

| Tool | `--save-csv` | Notes |
|------|--------------|-------|
| `fetch-entities` | yes | Preserves pagination metadata in the CSV response |
| `match-business` | yes | Returns one CSV result object |
| `match-prospects` | yes | Returns one CSV result object |
| `enrich-business` | no for cowork enrich payloads | Cowork enrich responses return stringified `enrichment_results`; capture raw JSON instead |
| `enrich-prospects` | no for cowork enrich payloads | Cowork enrich responses return stringified `enrichment_results`; capture raw JSON instead |

## Autocomplete First

When the search input is a free-text description and the target filter is one of the MCP autocomplete fields, run `autocomplete` before any `fetch-entities` or `fetch-entities-statistics` call. Use it to get the correct terminology, standardized values, or close matching terms, then use those returned values in the fetch call instead of the raw user wording.

Available autocomplete fields from the MCP schema:

- `naics_category`
- `linkedin_category`
- `company_tech_stack_tech`
- `job_title`
- `business_intent_topics`
- `city_region`

If autocomplete returns multiple relevant terms, prefer the best standardized match or include the relevant returned values explicitly in the fetch filter.

## Clarify Before Export

Do not ask the user to choose a mode up front. Use `Sample mode` first unless they explicitly requested full/export execution.

Before the full export run, make sure these scope details are clear if they materially affect the result:

1. Export size: how many records the user wants in the full export, and whether results should be capped.
2. Filter narrowing: industry (`linkedin_category` / `naics_category`), company size, revenue, region/state, tech stack.
3. For prospect queries: exact title variants to include or exclude, for example `founder/CEO` and `interim CEO`, and whether to dedupe by company.
4. For contact enrichment: professional email only, or also personal emails and phones.
5. Budget/credit ceiling the user is comfortable spending.

Use the sample results to surface ambiguity early. Always confirm the desired export size before the full export unless the user already stated it explicitly. Ask any other concise follow-up questions only when a missing scope detail would materially change the full export.

## Reference Docs First

Use the reference docs as the default source of truth for workflow and request shape.

- The reference docs now include compact call schemas, workflow intent, tool-specific caveats, and recommended sequencing.
- Read the matching reference doc before the first real use of an ability in a task.
- Use `--all-parameters` only when the reference doc does not provide enough detail for the payload you need, or when a real call fails and you need to debug the schema.
- If the reference doc and live schema appear to conflict, trust the live schema for exact field names and payload shape, but keep the reference doc's workflow guidance.

## Ability Docs

- [`autocomplete.md`](references/autocomplete.md) - controlled vocab lookups before searching
- [`fetch.md`](references/fetch.md) - use `fetch-entities` / `fetch-entities-statistics` in cowork mode, plus entity event retrieval workflows
- [`match.md`](references/match.md) - resolve known entities into canonical IDs
- [`enrich.md`](references/enrich.md) - enrich businesses and prospects after you have IDs
- [`fetch-stats.md`](references/fetch-stats.md) - counts and market-sizing queries without fetching records
- [`enums.md`](references/enums.md) - consolidated fixed enums and common filter values

## Default Workflow

**This rule applies the first time you use a tool in a task. Read the matching reference doc first. Use `--all-parameters` only if the reference schema is missing needed detail or the real call fails and you need to inspect the live schema.**

**Unless the user explicitly asked for full/export execution, the first fetch in a conversation should be a `Sample mode` call with `page_size: 5`. Treat that as the first batch. Move to `Export mode` only after the user approves the sample, and confirm the desired export size before the full export unless they already gave it.**

```
Step 0  ->  Complete setup and login from `login.md`
Step 1  ->  npx @vibeprospecting/vpai@latest --help    Discover available tools and their descriptions
Step 2  ->  Read the matching reference doc in `references/` for workflow guidance and caveats
Step 2.5 ->  Unless the user explicitly requested full/export execution, first run a sample fetch with `page_size: 5` as the first batch.
Step 3  ->  npx @vibeprospecting/vpai@latest <tool> --args '<json>'    Execute the tool using the reference doc schema
Fallback -> npx @vibeprospecting/vpai@latest <tool> --all-parameters   Use only if the reference schema is insufficient or the real call errors
Optional ->  add --save-csv to fetch-entities / match calls when you want the result rows written as CSV
Mode rule ->  in `Sample mode`, use `page_size: 5` for the first batch; before `Export mode`, confirm the desired export size unless the user already gave it; in `Export mode`, use `--save-csv` for fetch-entities / match and capture raw JSON for cowork enrich calls
```

Never make the first real call to a tool without reading its matching reference doc first. If the call shape is still unclear or the tool errors, inspect the live schema with `--all-parameters` before retrying.

## Flags

| Flag | Description |
|------|-------------|
| `--help` | List all tools with descriptions |
| `--all-parameters` | Print input and output JSON schemas (fallback for missing doc detail or error debugging) |
| `--args '<json>'` | Tool arguments as a JSON string |
| `--json` | With `--all-parameters`, output schemas as compact JSON |
| `--save-csv` | Extract supported row-shaped results and write CSV output. Use for fetch-entities and match by default. Cowork enrich responses are usually stringified and should be captured as raw JSON instead. |

---

## Output and Pagination

- All tool responses are JSON payloads. Read fields from the JSON exactly as returned.
- For fetch-entities and match calls, adding `--save-csv` writes the returned rows to CSV using the response-derived schema.
- In `Sample mode`, keep responses intentionally small and use `page_size: 5` for the first batch.
- In export mode, treat saved CSV files as the primary artifact for fetch-entities / match results, and raw JSON files as the primary artifact for cowork enrich results.
- Fetch and match return a single CSV result object with `file_path`, `columns`, `row_count`, and `source`.
- `--save-csv` responses preserve pagination metadata when available: `next_cursor` is passed through, and if no cursor exists but the tool returns a `page` object, that `page` object is included in the CSV metadata response.
- Non-cowork array-shaped enrich responses can still produce multiple sibling enrichment tables. In that case `--save-csv` returns `files`, with one CSV entry per enrichment key.
- The CSV columns come from the returned row shape: fetch-entities uses `data[]`; match uses `matched_businesses[]` or `matched_prospects[]`; array-shaped enrich responses use each sibling `{enrichment}.data[]` array.
- Do not paste large raw result payloads into the chat context if you can avoid it.
- Prefer saving substantial results to files and working from those files so context stays focused and reusable.
- Prefer this capture pattern when you need to inspect raw JSON without pasting it into chat: redirect to a file under the same pre-selected folder as `TMPDIR` (or `/tmp/resp.json` only when that folder is acceptable), then extract only the needed fields with `python3 -c 'import json; ...'`.
- In responses, summarize the relevant findings and reference the saved file instead of dumping the full payload.
- If a result set can exceed 50 items, prefer export mode and use pagination instead of assuming the first response is complete.
- Pagination can work in two ways: page-number pagination or cursor pagination.
- Prospect fetches typically return `next_cursor` via `page.next_cursor`. Business fetches may return a `page` object without a reusable cursor. Pass any returned cursor token verbatim.
- For page-number pagination, set `page_size` and advance `page` until you have enough results or the response stops returning new items.
- For cursor pagination, send the first request with `"next_cursor": null`, then pass the returned `next_cursor` value into the next request.
- Keep every other filter and request option the same when advancing `next_cursor`; only the cursor value should change between pages.
- Treat the returned `next_cursor` as an opaque token. Do not edit, parse, or generate it yourself.
- Each response gives you the token for the following page. If the response has no usable `next_cursor`, pagination is finished.
- In export mode, keep writing each paginated result to files instead of pasting page payloads into chat.
- Stop when the response returns no new items or no usable next cursor.
- Example page-number pattern: page 1 with `page_size: 50`, then page 2, page 3, and so on.

```bash
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"company_country_code":{"values":["US"]}},"page_size":50,"page":1}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"company_country_code":{"values":["US"]}},"page_size":50,"page":2}'

# Cursor pagination
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"company_country_code":{"values":["US"]}},"page_size":50,"next_cursor":null}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"businesses","filters":{"company_country_code":{"values":["US"]}},"page_size":50,"next_cursor":"<next_cursor_from_previous_response>"}'
```

---

## Filter Pattern

All filters follow the same shape:
```json
{ "values": ["value1", "value2"], "negate": false }
```
Set `"negate": true` to **exclude** those values instead of including them.

Range filters use `gte`/`lte`:
```json
{ "gte": 6, "lte": 24 }
```

Boolean filters are plain `true` / `false` / `null` (not wrapped in `values`).

---

## Common Multi-Step Workflows

In the examples below, replace **`SESSION_ID`** with the `session_id` string from the **previous** tool’s JSON for the same user request (skip on the first call of a new task).

### Authenticate then run a workflow

Run **Step 0** from **Auth** first, then continue below.

### Clean + enrich + find leaders at qualifying companies

```text
1. match-prospects(names/emails/linkedins)             -> prospect_ids
2. enrich-prospects(profiles)                          -> current company per prospect
3. match-business(distinct company names)              -> business_ids
4. enrich-business(firmographics)                      -> revenue / size / geography filter
5. enrich-business(challenges, strategic-insights)     -> pain points
6. fetch-entities(prospects, business_id in [...],
   job_level=[c-suite,vice president],
   job_department=[engineering])                       -> leaders
7. enrich-prospects(contacts) on the selected leaders  -> emails / phones
```

Use this as a fill-in-the-values template for company qualification plus leadership targeting workflows.

### "Tell me everything about Stripe"
```bash
npx @vibeprospecting/vpai@latest match-business --args '{"businesses_to_match":[{"name":"Stripe","domain":"stripe.com"}]}'
npx @vibeprospecting/vpai@latest enrich-business --args '{"session_id":"SESSION_ID","business_ids":["<id>"],"enrichments":["firmographics","technographics","funding-and-acquisitions","competitive-landscape","strategic-insights","workforce-trends"]}'
```

### "Find VP Engineering contacts at SaaS companies in New York"
```bash
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"linkedin_category","query":"software"}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"session_id":"SESSION_ID","entity_type":"prospect","filters":{"job_level":{"values":["vice president"]},"job_department":{"values":["engineering"]},"linkedin_category":{"values":["Software Development"]},"company_region_country_code":{"values":["US-NY"]},"has_email":true}}'
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"session_id":"SESSION_ID","prospect_ids":["pro_1","pro_2","pro_3"],"enrichments":["contacts","profiles"]}'
```

### "Find companies that just raised funding and use Salesforce"
```bash
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"company_tech_stack_tech","query":"salesforce"}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"session_id":"SESSION_ID","entity_type":"business","filters":{"company_tech_stack_tech":{"values":["Salesforce"]},"events":{"values":["new_funding_round"],"last_occurrence":60}}}'
npx @vibeprospecting/vpai@latest fetch-businesses-events --args '{"session_id":"SESSION_ID","business_ids":["<ids>"],"event_types":["new_funding_round"],"timestamp_from":"2024-10-01"}'
```

### "Who are the decision makers at our top accounts?"
```bash
npx @vibeprospecting/vpai@latest match-business --args '{"businesses_to_match":[{"domain":"company1.com"},{"domain":"company2.com"}]}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"session_id":"SESSION_ID","entity_type":"prospect","filters":{"business_id":{"values":["biz_1","biz_2"]},"job_level":{"values":["c-suite","vice president","director"]},"has_email":true}}'
npx @vibeprospecting/vpai@latest enrich-prospects --args '{"session_id":"SESSION_ID","prospect_ids":["<ids>"],"enrichments":["contacts","profiles"]}'
```

### "Market sizing: US healthcare IT"
```bash
npx @vibeprospecting/vpai@latest autocomplete --args '{"field":"linkedin_category","query":"health"}'
npx @vibeprospecting/vpai@latest fetch-entities-statistics --args '{"session_id":"SESSION_ID","entity_type":"business","filters":{"linkedin_category":{"values":["Health, Wellness & Fitness","Hospital & Health Care"]},"company_country_code":{"values":["US"]}}}'
```

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `npx @vibeprospecting/vpai@latest` fails to run | Verify `npx` can reach npm and retry the command |
| Auth / 401 / not authenticated | Do **Auth -> Step 0** via [`login.md`](references/login.md), then retry the same `npx @vibeprospecting/vpai@latest ...` command. |
| Empty results | Read the matching reference doc, then run `--all-parameters` only if the doc schema is not enough to debug the payload |
| Search fails with autocomplete fields | Call `autocomplete` first for `linkedin_category`, `naics_category`, `company_tech_stack_tech`, `job_title`, `business_intent_topics` |
| `linkedin_category` + `naics_category` together | Mutually exclusive - use one or the other |
| JSON parse error | Validate JSON; check shell quoting |
| Timeout | Default 120 s; reduce `page_size` or simplify filters |
