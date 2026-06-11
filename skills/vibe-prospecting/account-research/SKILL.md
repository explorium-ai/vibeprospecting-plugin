---
name: account-research
description: Produce a high-signal intelligence brief on a target company using Explorium firmographics, technographics, funding, hiring and challenge signals, business events, recent website and LinkedIn moves, plus a peer cohort. Identify the account by Explorium business_id (preferred) or by company name or domain (which triggers a match step). Always lead with a TL;DR framed by the user's stated research purpose (QBR prep, competitive analysis, cold outbound, renewal risk, expansion).
---

# Account Research
Build a purpose-driven intelligence brief on a single target company, anchored on the user's stated reason for pulling the brief.

## Input
Via `$ARGUMENTS`:
- Account identifier (required), one of:
  - Preferred: an Explorium `business_id`. Use directly; skip the match step.
  - Fallback: a company name or domain. Resolve via `match-business` as a first step.
- Research context (strongly recommended): a sentence on *why* this brief is being pulled and what decision it supports. Examples: "QBR prep, focus on renewal risk and expansion levers", "competitive eval vs Acme, looking for displacement angles", "cold outbound, find a credible reason to reach out". This shapes enrichment selection, event triage, and the TL;DR framing.

Example phrasings:
- "Build a brief on stripe.com for cold outbound to finance leaders."
- "Account brief for business_id abc123, QBR next week, watch renewal signals."
- "Profile Snowflake, competitive analysis vs Databricks."

## Workflow
1. **Anchor on purpose.** Read the research context from `$ARGUMENTS`. If supplied, restate it in one sentence as the *brief purpose* and keep it as the framing lens. If missing, ask once. If the user declines or says "just general intel", default to general account intelligence and state that assumption at the top. Derive 2 to 4 priority themes (e.g., QBR renewal risk: workforce changes, exec moves, competing vendors, expansion signals). Themes drive enrichment selection in step 3.
2. **Resolve the company.** If a `business_id` was supplied, use it directly. Otherwise call `match-business` with the company name or domain. `match-business` returns only `business_id` (and the input echo); firmographics (company_name, headcount, revenue_range, industry, HQ) require a separate `enrich-business --type firmographics` call in step 3. Sanity check: if the resolved business_id's firmographics show a major-brand input but headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity; re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id. If no confident match, surface the ambiguity to the user before continuing rather than guessing. Pass `--tool-reasoning` on every call.
3. **Enrich in chunked calls (max 3 enrichments per call).** Treat each enrichment as context retrieval, not filtering. Call `enrich-business` with `--session-id` and `--table-name` (CLI batches 50; one company fits in a single batch). `enrich-business` accepts at most 3 enrichments per call. Capture the new `table_name` returned by each call (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. Tailor the enrichment set to the brief purpose:
   - Always (8 enrichments → 3 calls): Call 1 `[firmographics, company-hierarchies, funding-and-acquisitions]`; Call 2 `[challenges, strategic-insights, workforce-trends]`; Call 3 `[linkedin-posts, website-changes]`.
   - For competitive briefs: add another call `[competitive-landscape, technographics, webstack]`.
   - For QBR or renewal briefs: add `company-ratings` (workforce-trends and challenges already in the base set).
   - For investor or M&A angles: `financial-metrics` (supply `parameters.date` for the target quarter or year-end) goes in its own call alongside up to 2 others.
   - For category or keyword-driven outbound: add `website-keywords` with `parameters.keywords` derived from your offering or themes.
   Pass `--all-parameters` and `--tool-reasoning` on every call.
4. **Pull recent events.** Call `fetch-businesses-events --session-id <id> --table-name <prior_table>` (the table populated by the step 3 enrichment, which holds the resolved `business_id`) and scope the events filter to the last 90 days. Look for hiring spikes, leadership changes, funding rounds, product launches, layoffs, office moves, and tech adoption events. Keep `--tool-reasoning` on.
5. **Build the peer cohort (approximation).** Explorium has no native similar-companies tool. Approximate it: take firmographics + technographics + a NAICS sub-category (e.g. `518210` Data Processing) rather than just `linkedin_category` to avoid the mega-tech default-ordering problem (live-tested with a `linkedin_category: "software development"` peer query for Databricks that returned Google/Amazon/Meta). Call `fetch-entities-statistics` for businesses sharing the tighter sub-NAICS, similar `company_size` bucket, and same `company_country_code` to confirm cohort volume. Country caveat: `fetch-entities-statistics` does NOT strictly enforce `company_country_code`; `total_results` is the global count for the non-country filters. For country-scoped cohort size, read `stats.business_categories_per_location[<category>][<country>]` and sum across the requested ISO-2 codes, never `total_results`. Then `fetch-entities` with the same filters for the top 10 to 20. Flag explicitly in the output that this is a directional peer set, not an exact match list.
6. **Synthesize.** Triage every retrieval against the brief purpose:
   - Events and signals: keep items mapping to the purpose, priority themes, or non-obvious signals worth flagging. Drop noise.
   - Past-date flag: if any enrichment surfaces dates in the past (funding close, exec start date, last website change), flag them as needing verification (active vs stale).
   - Section suppression: skip funding for public mega-caps (reference ticker), skip peer cohort if step 5 returned fewer than 5 confident matches, flatten challenges or strategic insights if only 1 to 3 items.
   - Cross-reference: a new CTO from LinkedIn posts plus a recent webstack change plus a hiring spike in engineering equals a clear timing signal. Connect the dots back to the user's stated goal.
7. **Write the exec summary last.** Re-read the body, then write the TL;DR. The Situation line must explicitly answer *why this brief, now* against the user's stated purpose.

## Output Format
### TL;DR: [Company Name]
*Brief purpose: [restate user's research context in one line, or "general account intelligence (no purpose supplied)" if defaulted].*

**Situation.** 2 to 4 sentences answering *why this brief, now* against the stated purpose: who they are, the dominant story now, and the specific signal(s) that make this purpose timely.

**Top 3 facts.** Three most consequential data points across all sources.

**Highest-leverage actions.** 1 to 3 concrete actions, each tied to a specific signal, person, or moment surfaced below.

---

### Company Snapshot
| Field | Value |
|-------|-------|
| Domain | |
| LinkedIn Category | |
| NAICS Category | |
| Company Size (bucket) | |
| Headcount | |
| Revenue (bucket) | |
| HQ Country / Region | |
| Public / Private | |
| Founded | |
| Explorium business_id | |

### Firmographics & Hierarchy
Summarize the firmographics enrichment plus parent / subsidiary structure from `company-hierarchies`. Note any recent restructuring.

### Funding & Capital Structure
List total raised, most recent round date and amount, and acquisitions. For public mega-caps (revenue bucket 5001-10000 or 10001+ and is_public_company true), replace with "Public company. See ticker for capital structure."

### Workforce & Hiring Signals
Summarize `workforce-trends`: net headcount change, departmental growth, recent hiring spikes or contractions. Flag any exec moves surfaced via `linkedin-posts` or events.

### Tech Stack & Website Activity
From `technographics`, `webstack`, `website-changes`, and `website-keywords` (if pulled): tools in use, recent additions or removals, keyword shifts. Highlight any items mapping to the user's offering or competitors.

### Challenges & Strategic Insights
From `challenges` and `strategic-insights`: stated pain points, public priorities, expansion plans. Tie to brief purpose.

### Recent Events (last 90 days)
From `fetch-businesses-events`: grouped list (Funding / Leadership / Hiring / Product / Risk) only if 4 or more items span categories, otherwise flat. Each item: event type, date, one-line summary. Call out timing opportunities (e.g., new CTO equals vendor evaluation likely).

### Peer Cohort (directional)
Lead with a one-line caveat: this peer set is approximated from shared `linkedin_category`, `company_size`, and `company_country_code`, not an exact similarity score. Then show the top 10:

| # | Company | Domain | Size | Revenue | Country |
|---|---------|--------|------|---------|---------|

### Key Takeaways & Next Steps
3 to 5 bullets connecting the dots across sources, framed by the user's stated purpose. Then suggest concrete next actions tied to specific signals, people, or moments surfaced above. Omit any line without a concrete target.

## Limitations
- `strategic-insights` and `challenges` enrichments are sourced from SEC 10-K filings; for private companies these will be all-null, and for public companies the data can be 12-18 months stale. Use `fetch-businesses-events`, `funding-and-acquisitions`, `workforce-trends`, and `linkedin-posts` for current-state signals.
- No native similar-companies tool. Peer cohort is approximated via shared `linkedin_category` + `company_size` + `company_country_code`; flagged as directional, not exact.
- No native intent-topic scoring. Intent-style signals come from `fetch-businesses-events`, `website-changes`, `website-keywords`, and `linkedin-posts` rather than a single ranked topic feed.
- No AI-generated outbound copy. This skill produces the brief; downstream skills handle message generation.
- Bucket-only employee count and revenue. Exact headcount or ARR may appear inside firmographics enrichment but filters and peer cohort use buckets.
- `is_public_company` is the only company-type filter; finer distinctions (subsidiary, JV, PE-backed) must be read from `company-hierarchies` and `funding-and-acquisitions` enrichments rather than filtered.
