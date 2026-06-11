---
name: account-fit-rank
description: Rank a list of accounts (mixed Explorium business IDs, company names, or domains) by ICP fit, buying intent, recent triggers, and workforce momentum. Returns per-account composite score (0-100), tier (A/B/C), explainable component breakdown (fit / intent / trigger / workforce), and a specific "why now" sentence per account anchored on a real Explorium signal. Resolves name/domain inputs via match-business with explicit confirmation for ambiguous matches. Iteratively refinable. Use for account-based selling, ABM list prioritization, territory planning, signal-based selling, buyer-intent ranking, and B2B prospecting. Triggers on "score these accounts", "rank by ICP fit and intent", "prioritize this account list", "which accounts should I work first", "build a tiered account list", "ICP scoring", "account prioritization".
---

# Account Fit Rank
Score and tier a list of accounts on four axes by fetching firmographics, technographics, intent, events, and workforce trends from Explorium, then applying a transparent weighted composite the calling model computes from the returned data.

## Input
- Accounts (required): list of Explorium business IDs, company names, domains, or a mixed CSV.
- Use case (default `prospecting`): one of `prospecting`, `abm`, `territory_planning`, `pipeline_acceleration`. Shifts tier thresholds and recommended actions.
- ICP definition (required from user or session memory): industries / naics, employee buckets, revenue buckets, country or region, optional tech-stack vendors, optional intent topics. No persisted ICP exists in tool surface, so capture it inline.
- Weight overrides (optional): `{fit, intent, trigger, workforce}` summing to 100. Default `45 / 25 / 25 / 5`.
- Tier thresholds (optional): `{A, B}`. C is the remainder. Default `A>=75, B 50-74`.

## Workflow

### 1. Lock the ICP and intent topics
Restate the ICP from the user. For each tag-style field, resolve it: `autocomplete --field linkedin_category --query <theme>` (or `naics_category` if the user is NAICS-native, never both), `autocomplete --field company_tech_stack_tech --query <vendor>` for technographic ICP checks, `autocomplete --field business_intent_topics --query <topic>` for each topic theme one at a time (fuzzy multi-term queries fail silently). If a tag does not resolve, drop it and flag that axis as configuration-gap, not signal-absent.

### 2. Resolve identifiers (four-bucket routing)
Route inputs by shape:
- Existing Explorium business ID -> auto-resolved.
- Domain -> `match-business` with `{domain: <value>}`. Single confident match -> auto-resolved. Multiple plausible -> ambiguous.
- Name -> `match-business` with `{name: <value>}`, optionally `{name, country}` when the user supplied geography. Top match clearly dwarfs alternatives on headcount / revenue / domain root -> auto-resolved. Clear top but plausible alternatives -> verified with a flag. No dominant winner -> ambiguous.
- No candidate returned -> failed.

Never silently pick a winner. For ambiguous rows, present the top 5 candidates (company_name, company_domain, headcount, revenue_range, country) and ask for confirmation. For high-collision names with no tiebreaker, require domain confirmation before scoring. If two top candidates share the same domain root and similar revenue / metro, flag suspected duplicate and offer to union the records, since signals may be split across them. Resolution must end at 100% accountability: every input is auto-resolved, verified, ambiguous, or failed.

Sanity check after match-business: if the resolved business_id's firmographics show a major-brand input but headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity. Re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id.

### 3. Pre-flight relationship context
Tag each resolved account against the user-supplied competitor / customer / partner lists before scoring: `competitor`, `customer`, `partner`, or `prospect` (default). Surface the tag on the row before the tier letter so a "pursue this competitor" line is never produced silently.

### 4. Fetch firmographic, technographic, and signal data
Process accounts in chunks of ~25 end-to-end (resolve -> fetch -> score -> compose row -> discard raw payloads) so a long list never blows context. For each chunk, persist results to one session table: pass the resolved business IDs as `--businesses-table-name account_fit_rank_<run>` (the resolution table built in step 2) and run the calls below in batches of 50.

Per chunk, run these Explorium calls against the same session and table. `enrich-business` accepts at most 3 enrichments per call, so chunk the enrichments. Capture the new `table_name` returned by each enrich call (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns.
- Call 1: `enrich-business --type firmographics technographics linkedin-posts --session-id <sid> --table-name account_fit_rank_<run>` (industry/headcount/country/age, tech-stack if ICP names vendors, last-90-days organic activity).
- Call 2: `enrich-business --type funding-and-acquisitions workforce-trends strategic-insights --session-id <sid> --table-name <view_from_call_1>` (funding/M&A, headcount delta and hiring surges, executive moves and priorities).
- Call 3: `enrich-business --type website-changes --session-id <sid> --table-name <view_from_call_2>` (product/page launches in window).
- `fetch-businesses-events --session-id <sid> --table-name <view_from_call_3>` filtered to high-signal event types in the last 90 days (funding rounds, leadership changes, product launches, expansions). The session table already holds the chunk's business IDs. Use the events filter directly; no autocomplete needed for the events list. Note: `fetch-businesses-events` uses `timestamp_from` (a single date floor, no upper bound) for the time window; `fetch-entities` events filter uses `last_occurrence` (bounded 30-90 days). Pick the right tool per the time window needed.

If the ICP includes an intent dimension, separately call `fetch-entities-statistics --entity businesses --session-id <sid> --filter '{"business_id": {"values": [<resolved business_ids from match-business>]}, "business_intent_topics": {"values": [<resolved topic ids>]}}'` to read which accounts are surfacing the resolved topics. Note: stats can't use `--businesses-table-name`; that flag only works on `fetch-entities`. Scope stats with `filters.business_id.values` directly. If no topics resolved in step 1, set intent weight = 0 and redistribute.

Keep concurrency reasonable per chunk and drop raw payloads after extracting the per-axis inputs and the single winning signal for "why now."

### 5. Score each axis (calling model computes from the fetched data)

Fit (0-100). Compare firmographics to the ICP, banded:
- Industry / naics primary match = 25, adjacent = 10, miss = 0.
- Employee bucket (`company_size`) in band = 20, one bucket off = 12, two off = 4, outside = 0.
- Revenue bucket (`company_revenue`) same banding, max 20.
- Geography: ICP country = 15, in ICP region = 8, outside = 0.
- Company age within ICP `company_age` window = 10, else 0.
- Technographic vendor match (if specified): present in `company_tech_stack_tech` = 10, else 0.

Intent (0-100). Derived from intent-topic exposure for the account against the curated topic set. If the account is surfacing 3+ resolved topics, score 90; 2 topics 70; 1 topic 50; 0 topics 0. Record the strongest topic for "why now." If no topics resolved at all, axis = 0 with `configuration-gap` flag and weight redistributed.

Trigger (0-100). For each event from `fetch-businesses-events`, `funding-and-acquisitions`, `strategic-insights`, and `website-changes` in the last 90 days, compute `event_score = type_weight * recency_factor`:
- M&A, funding round, new CEO / C-suite move = 95.
- Product launch, hiring surge, major website change = 75.
- Partnership, new facility / expansion = 55.
- Generic announcement = 25.
- Recency: 0-14d = 1.0, 14-30d = 0.7, 30-60d = 0.4, 60-90d = 0.2, older = 0.

Account trigger = max event_score, capped at 100. Record the winning event for "why now." If both event feeds are empty, trigger = 0 with `no fresh trigger` flag.

Workforce (0-100). From `workforce-trends` and `linkedin-posts`:
- Headcount up 10%+ in 90 days OR a target-department hiring surge = 80-100.
- Modest growth or steady hiring in the right team = 40-70.
- Flat or shrinking = 10-30.
- No data = null -> redistribute weight.

### 6. Composite, tier, and "why now"
Composite = round((fit*w_fit + intent*w_intent + trigger*w_trigger + workforce*w_workforce) / 100). Cap any axis with no data at null and redistribute that weight proportionally across the remaining axes; surface the redistribution in the output. Assign tier from thresholds (use-case overrides: `abm` -> A=80 / B=55, `pipeline_acceleration` -> A=65 / B=40, others use defaults).

"Why now" is one sentence anchored on the strongest underlying signal, never the composite restated. Examples: "Closed Series C 12 days ago and hiring across RevOps." "Three intent topics active in the last 30 days, lead topic is data enrichment." "Perfect-fit ICP, no fresh trigger, pursue on fit alone." For strong trigger but low fit, be explicit: "Do not pursue, fresh CEO change but bucket mismatch on revenue keeps this in C."

### 7. Iterate
After presenting, offer: adjust weights and recompute composite from cached axes; tighten or loosen tier thresholds; refilter to drop tier C or specific industries; swap the ICP definition; drill into one account (re-run the per-account fetch with deeper enrichment such as `challenges`, `competitive-landscape`, `company-ratings`); add accounts and rescore. Only the "add accounts" or "swap ICP" paths require new Explorium calls; weight / threshold tweaks reuse cached axes.

## Output Format

### TL;DR
Account Fit Rank, N accounts, pass [M]. Use case: [restate]. Weights `fit/intent/trigger/workforce`. Thresholds A>=[X], B [Y-Z].
- Resolution: [R resolved, A ambiguous, F failed]. If A > 0, mark "user confirmation required."
- Tier distribution: A: x, B: y, C: z.
- Top 3 with one-line "why now" each.

### Resolution Summary
| Input | Resolved To | Business ID | Confidence | Status |

Status legend: auto-resolved, verified, ambiguous, failed. For each ambiguous row, list up to 5 candidates with `company_name, company_domain, headcount, revenue_range, country` and ask the user to pick.

### Ranked Accounts
Sorted by composite descending. Use `-` in any axis column that was redistributed.

| # | Account | Tag | Tier | Composite | Fit | Intent | Trigger | Workforce | Why now | Business ID |

### Weights and Axes Used
```
fit:       [%]
intent:    [%]
trigger:   [%]
workforce: [%]   (redistributed if axis unavailable)
```
Axes missing this run: [list, or "none"].

### Recommended Actions per Tier
- Tier A: route to AE for 1:1 outreach within 24h, prioritize contact enrichment.
- Tier B: SDR sequence using the why-now as opener, retarget for ABM.
- Tier C: monitor, rescore weekly when fresh events land.

### Iteration Options
1. Accept ranking and freeze the ICP and weight set.
2. Adjust weights and recompute from cached axes.
3. Tighten or loosen thresholds.
4. Refilter (drop tier C, drop an industry).
5. Swap the ICP definition.
6. Drill into one account with deeper enrichment.
7. Add accounts and rescore.

### Caveats (when relevant)
- Ambiguous pending: N accounts not yet scored.
- Failed resolutions: N inputs had no match.
- Intent axis configuration-gap when fewer than half of curated topics resolved through `autocomplete --field business_intent_topics`.
- Stale-signal cliff: N accounts' best trigger is 60-90 days old.
- Workforce axis null for N accounts and weight redistributed.

## Limitations
- `strategic-insights` and `challenges` enrichments are sourced from SEC 10-K filings; for private companies these will be all-null, and for public companies the data can be 12-18 months stale. Use `fetch-businesses-events`, `funding-and-acquisitions`, `workforce-trends`, and `linkedin-posts` for current-state signals.
- No native scoring engine exists in the Explorium tool surface; the composite and tiering are computed by the calling model from the data Explorium returns. Do not promise an Explorium-side score.
- Employee count and revenue are bucketed (`company_size`, `company_revenue`), not exact, so band-distance scoring is the right resolution.
- Engagement axis (CRM deal stage, last activity, named champion) is not available from the Explorium tool surface; this skill substitutes a `workforce` axis derived from `workforce-trends` and `linkedin-posts` and surfaces the gap rather than inventing CRM data.
- `linkedin_category` and `naics_category` are mutually exclusive on filters; pick one taxonomy per run.
- No similar-companies, metro taxonomy, or Inc / Fortune ranking helper; geography is country or region only.
