---
name: "vibe-prospecting"
description: "Find company & contact data. Turn your agent into a prospecting platform. Get contact information, roles, tech stack, business events, website changes, intent data. Build lead lists, research prospects, identify talent. 150M+ companies, 800M+ professionals, 50+ data sources."
compatibility: Run with npx @vibeprospecting/vpai@latest
metadata:
  version: "0.1.28"
---

# Vibe Prospecting CLI

Run with `npx @vibeprospecting/vpai@latest`. The CLI executes tools against the Vibe Prospecting MCP server (`https://mcp.explorium.ai/mcp`) and returns raw JSON results. Treat every tool response as JSON, not prose.

## Prerequisites

1. **Use the CLI command**: `npx @vibeprospecting/vpai@latest ...`
2. **Login and setup first**: complete the initial CLI setup and auth flow in [`login.md`](references/login.md) before running tools.

## Auth

Complete first login and setup via [`login.md`](references/login.md) before using this skill.

## Tool reasoning

When you run a tool for real (anything other than **only** `<tool> --all-parameters` with **no** `--args`), the CLI requires **`--tool-reasoning '<text>'`**.

Put the **end-user request** that this call is fulfilling in that text: **their wording** from the chat (what they asked you to find or do). The CLI sends it as MCP `tool_reasoning`. Do **not** use a separate “why I picked this tool” explanation instead of the user’s request.

You **do not** pass `--tool-reasoning` when you are **only** inspecting schemas: `npx @vibeprospecting/vpai@latest <tool> --all-parameters` with no `--args`.

Example:

`npx @vibeprospecting/vpai@latest match-business --args '{"businesses_to_match":[{"name":"Google"}]}' --tool-reasoning 'User asked to identify Google as a company'`

## Session ID

Optional **`session_id`** belongs **inside** the `--args` JSON (no separate flag). Reuse the exact string from the **previous** tool’s JSON in the **same** user task (including from autocomplete when the body is `{ "data": [...], "session_id": "..." }`). Omit it when the user starts a **new unrelated** ask.

## Task Mode Selection

At the start of every new user task, ask one short mode-selection question before running the workflow:

- `Research mode` (exploratory): first explore a small sample so the user can see the shape of the result, validate that the query is right, and understand what information is available and what follow-up filters or enrichments may be useful.
- `Direct mode`: execute the requested workflow immediately.
- `Export mode`: run the workflow in file-first mode so large result sets stay out of chat context.

Explain briefly that starting with exploration usually produces a better final task because it lets the user preview the result shape and confirm what the search can and should return before spending more credits.

If the user already clearly requested one of these modes, follow it without asking again.

## Research Mode

- Use this when the user wants an exploratory pass before the full workflow.
- Keep the requested result size small: use `size: 5` when the tool supports it.
- Keep pagination narrow and do not expand into large result sets unless the user approves the next step.
- Summarize what the sample shows: result shape, relevant fields, likely next filters, and what a larger run would return.
- After the exploratory pass, ask whether to continue with the full workflow or refine the query first.

## Export Mode

- Use file-first output handling.
- For `fetch-entities`, `match`, and `enrich` calls, always add `--save-csv`.
- Work from the saved files instead of pasting large raw payloads into chat.
- Prefer export mode whenever the result can exceed 50 rows or when the user asks for a deliverable/output file.
- In chat, return a concise summary plus the saved file path(s).

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

## Clarify Before Fetch

Before large `fetch-*` or `enrich-*` execution, use `AskUserQuestion` to confirm the mandatory scope details.

1. Target record count and whether results should be capped.
2. Filter narrowing: industry (`linkedin_category` / `naics_category`), company size, revenue, region/state, tech stack.
3. For prospect queries: exact title variants to include or exclude, for example `founder/CEO` and `interim CEO`, and whether to dedupe by company.
4. For contact enrichment: professional email only, or also personal emails and phones.
5. Budget/credit ceiling the user is comfortable spending.

Proceeding without these answers on a large fetch is a skill violation.

## Reference Docs First

Do not rely on `--all-parameters` alone.

- `--all-parameters` is required for schema inspection.
- The reference docs explain workflow intent, tool-specific caveats, output shape, and recommended sequencing.
- Before the first real use of an ability in a task, read its matching reference doc and then inspect `--all-parameters` for the exact schema.
- If the reference doc and schema appear to conflict, trust the live schema for exact field names and payload shape, but keep the reference doc's workflow guidance.

## Ability Docs

- [`autocomplete.md`](references/autocomplete.md) - controlled vocab lookups before searching
- [`fetch.md`](references/fetch.md) - use `fetch-entities` / `fetch-entities-statistics` in cowork mode, plus entity event retrieval workflows
- [`match.md`](references/match.md) - resolve known entities into canonical IDs
- [`enrich.md`](references/enrich.md) - enrich businesses and prospects after you have IDs
- [`fetch-stats.md`](references/fetch-stats.md) - counts and market-sizing queries without fetching records

## Mandatory 3-Step Workflow

**This rule applies to every tool. The first time you use any tool, you must read the matching reference doc and then run that exact tool with `--all-parameters` before executing it with `--args`. Only after you have read the reference doc and inspected that tool's schema may you skip `--all-parameters` on later calls to the same tool.**

**The first fetch/enrich in a conversation MUST be preceded by an `AskUserQuestion` scoping call unless the user already provided count + filters + enrichment preferences explicitly.**

```
Step 0  ->  Complete setup and login from `login.md`
Step 1  ->  npx @vibeprospecting/vpai@latest --help    Discover available tools and their descriptions
Step 2  ->  Read the matching reference doc in `references/` for workflow guidance and caveats
Step 2.5 ->  For any fetch/enrich with page_size > 50 OR total target > 100 records, you MUST call AskUserQuestion to confirm scope before executing Step 3.
Step 3  ->  npx @vibeprospecting/vpai@latest <tool> --all-parameters   Mandatory before the first call to every tool
Step 4  ->  npx @vibeprospecting/vpai@latest <tool> --args '<json>'    Execute the tool with JSON matching the schema
Optional ->  add --save-csv to fetch-entities / match / enrich calls when you want the result rows written as CSV
Mode rule ->  in research mode, prefer `size: 5` when supported; in export mode, always use `--save-csv` for fetch-entities / match / enrich
```

Never make the first call to a tool without doing steps 2 and 3 for that tool first. Skipping them can cause silent empty results, malformed payloads, or wrong workflow choices.

## Flags

| Flag | Description |
|------|-------------|
| `--help` | List all tools with descriptions |
| `--all-parameters` | Print input and output JSON schemas (do not call the tool) |
| `--args '<json>'` | Tool arguments as a JSON string |
| `--json` | With `--all-parameters`, output schemas as compact JSON |
| `--save-csv` | For fetch-entities / match / enrich calls, extract the returned rows and write CSV output. Fetch and match return one CSV file; enrich may return one CSV per enrichment table. |

---

## Output and Pagination

- All tool responses are JSON payloads. Read fields from the JSON exactly as returned.
- For fetch-entities / match / enrich calls, adding `--save-csv` writes the returned rows to CSV using the appropriate response-derived schema.
- In research mode, keep responses intentionally small and prefer `size: 5` when the tool supports it.
- In export mode, treat saved CSV files as the primary artifact for fetch-entities / match / enrich results.
- Fetch and match return a single CSV result object with `file_path`, `columns`, `row_count`, and `source`.
- Enrich responses may contain multiple sibling enrichment tables. In that case `--save-csv` returns `files`, with one CSV entry per enrichment key.
- The CSV columns come from the returned row shape: fetch-entities uses `data[]`; match uses `matched_businesses[]` or `matched_prospects[]`; enrich uses each sibling `{enrichment}.data[]` array.
- Do not paste large raw result payloads into the chat context if you can avoid it.
- Prefer saving substantial results to files and working from those files so context stays focused and reusable.
- In responses, summarize the relevant findings and reference the saved file instead of dumping the full payload.
- If a result set can exceed 50 items, prefer export mode and use pagination instead of assuming the first response is complete.
- Pagination can work in two ways: page-number pagination or cursor pagination.
- For page-number pagination, set `page_size` and advance `page` until you have enough results or the response stops returning new items.
- For cursor pagination, send the first request with `"next_cursor": null`, then pass the returned `next_cursor` value into the next request.
- Keep every other filter and request option the same when advancing `next_cursor`; only the cursor value should change between pages.
- Treat the returned `next_cursor` as an opaque token. Do not edit, parse, or generate it yourself.
- Each response gives you the token for the following page. If the response has no usable `next_cursor`, pagination is finished.
- In export mode, keep writing each paginated result to files instead of pasting page payloads into chat.
- Stop when the response returns no new items or no usable next cursor.
- Example page-number pattern: page 1 with `page_size: 50`, then page 2, page 3, and so on.

```bash
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"country_code":{"values":["US"]}},"page_size":50,"page":1}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"country_code":{"values":["US"]}},"page_size":50,"page":2}'

# Cursor pagination
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"country_code":{"values":["US"]}},"page_size":50,"next_cursor":null}'
npx @vibeprospecting/vpai@latest fetch-entities --args '{"entity_type":"business","filters":{"country_code":{"values":["US"]}},"page_size":50,"next_cursor":"<next_cursor_from_previous_response>"}'
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
npx @vibeprospecting/vpai@latest fetch-entities-statistics --args '{"session_id":"SESSION_ID","entity_type":"business","filters":{"linkedin_category":{"values":["Health, Wellness & Fitness","Hospital & Health Care"]},"country_code":{"values":["US"]}}}'
```

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `npx @vibeprospecting/vpai@latest` fails to run | Verify `npx` can reach npm and retry the command |
| Auth / 401 / not authenticated | Do **Auth -> Step 0** via [`login.md`](references/login.md), then retry the same `npx @vibeprospecting/vpai@latest ...` command. |
| Empty results | Read the matching reference doc, run `--all-parameters`, then verify filter field names |
| Search fails with autocomplete fields | Call `autocomplete` first for `linkedin_category`, `naics_category`, `company_tech_stack_tech`, `job_title`, `business_intent_topics` |
| `linkedin_category` + `naics_category` together | Mutually exclusive - use one or the other |
| JSON parse error | Validate JSON; check shell quoting |
| Timeout | Default 120 s; reduce `size` or simplify filters |
