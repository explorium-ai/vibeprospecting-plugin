---
name: decision-makers-map
description: Map the decision-makers and buying committee at a target account. Identifies economic buyers, champions, technical evaluators, and influencers; prioritizes who to engage first; surfaces coverage gaps and multi-thread risk. Leads with a TL;DR (top 3 to engage, biggest gap, single-thread risk), uses compact tables, and flags recently appointed leaders. Identify the account by company domain (preferred) or company name; include deal context, persona priorities, and any hypotheses to test.
---

# Decision-Makers Map
Map the buying committee at one target account: who matters, what role they play, and who to engage first.

## Input
The user supplies via `$ARGUMENTS` an account identifier plus optional context.

- Account identifier (required), one of:
  - Preferred: a company domain (e.g. `acme.com`). Resolve via `match-business`.
  - Fallback: a company name. Resolve via `match-business`.
- Research context (strongly recommended): a free-form description of why this map is being pulled and what decision it supports. Capture as much as is true: deal stage and value, offering in play, recent activity or stalls, who is already engaged, who is missing, competitive pressure, persona priorities (e.g. "security leadership", "VP Engineering and above"), timing constraints, and any working hypothesis to test.

Example phrasings:
- "Map the buying committee at acme.com. Stage 3 deal, $400K ARR, security platform. We talked to the Director of SecOps but the CISO is quiet: find the economic buyer and any procurement blockers."
- "Decision-makers at Globex for a Data Platform pitch. Cold prospecting, no prior engagement. Likely Eng or Data leadership, flag CFO if cost story applies."
- "Renewal in 90 days at initech.com, champion left last quarter. Find the new owner and anyone who could block renewal."

If only a bare token is supplied with no context, ask once for context. If declined, default to general committee mapping for prospecting and state that assumption in the TL;DR.

## Workflow
1. Anchor on purpose. Read `$ARGUMENTS` and restate the research context in 1-2 sentences as the map purpose. Derive: priority personas (3-6 job titles or functions, e.g. CISO, SecOps Director, Procurement Lead, CFO), priority `job_level` enums (common values: `c-suite`, `vice president`, `director`, `manager`; full enum has 15 values, consult `fetch-entities --all-parameters` for finer seniority), priority `job_department` enums (common values include `engineering`, `marketing`, `sales`, `it`, `operations`, `finance`; full enum has 29 values, consult `fetch-entities --all-parameters` for niche departments), and any named hypotheses to test (e.g. "find the economic buyer").

2. Resolve the account. Call `match-business` with the supplied domain or company name. `match-business` returns only `business_id`; to get firmographics (company_name, headcount, revenue_range, industry, HQ), call `enrich-business --type firmographics --session-id <id> --table-name <match_business_table>` immediately after. Capture the new `table_name` returned in the response (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. If the resolved business_id's firmographics show a major-brand input but the firmo headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity. Re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id. If no confident match, surface the ambiguity to the user before continuing rather than guessing.

3. Resolve filter values for the committee search. For every priority job title, call `autocomplete` with `field: job_title` and capture the returned strings plus the `session_id`. Reuse one session_id across the workflow so downstream calls stay consistent. Intersect `job_title` with `job_level` enum to tighten - the autocomplete-resolved values are not enforced as exact-match (a `job_title`-only filter for `Vice President of Engineering` returned 4 of 5 non-VP rows in live testing). Combine `job_title` with `job_level: {values: ["vice president"]}` for tight matches.

4. Size the committee. The `match-business` call in step 2 returns a businesses table (capture its name; for example `dm_map_accounts`). Call `fetch-entities-statistics --entity-type prospects --session-id <sid> --filter '{"business_id": {"values": [<resolved business_ids>]}, "job_title": {...}, "job_level": {...}}'` with the priority `job_title` values and the priority `job_level` enum. Note: `fetch-entities-statistics` does NOT support `--businesses-table-name`; that flag only works on `fetch-entities`. Scope stats with `filters.business_id.values` directly (a `company_domain` filter is not a valid filter field either). Country caveat: when scoping by country, `fetch-entities-statistics` does NOT strictly enforce `company_country_code`. `total_results` is global; for country-scoped committee counts read `stats.business_categories_per_location[<category>][<country>]` and sum the requested ISO-2 codes. Capture the total. If the total is very large (above ~500) tighten with `job_department` or higher `job_level`; if very small (under ~10) loosen by adding adjacent titles or dropping `job_level`.

5. Pull the committee broadly (retrieval, not filtering). Call `fetch-entities --entity-type prospects --session-id <sid> --businesses-table-name dm_map_accounts --table-name dm_map_committee` with the same title + level filters plus `has_email: true` as a contact-quality proxy. Note: `fetch-entities` preview is hard-capped at 5 rows regardless of `--number-of-results`. The full slice only materializes via `export-to-csv` (paid). For interactive use, treat the 5-row preview as a sanity sample, not as the ranked top-N. Separately, run a second `fetch-entities` pass (same flags, different priority titles) for adjacent functions named in the context (e.g. Procurement, Legal, Finance) if they were not in the priority titles, so coverage gaps are visible.

6. Account context signals. In parallel with step 5, call `fetch-businesses-events --session-id <sid> --table-name dm_map_accounts` and scope the events filter to the last 90 days. `fetch-businesses-events` has no executive-move or departure enum. Closest signals: `employee_joined_company` (all hires, undifferentiated by seniority) and `hiring_in_<department>_department`. For executive-level moves specifically, the data isn't surfaced here - flag this as a gap in the brief. Also triage funding/strategy signals that change the buying dynamic. Optionally call `enrich-business --session-id <sid> --table-name dm_map_accounts --enrichments firmographics strategic-insights` to back the Company Snapshot and GTM Fit sections (combine up to 3 enrichments per call); add `challenges` and `competitive-landscape` when the context names a competitor or a named hypothesis ties to a strategic theme.

7. Enrich and deep-research the top contacts.
   - Merge prospects from step 5, dedupe by `prospect_id`.
   - Rank by seniority (`job_level`), fit to priority personas, fit to named hypotheses, and presence of `email` / `linkedin_url`.
   - Call `enrich-prospects --session-id <sid> --table-name dm_map_committee --enrichments contacts profiles --contact-types email` on the top 20 merged prospects (CLI batches 50). Cost is ~2 credits per row (email-only) vs ~5 credits per row (email + phone). Switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). For top 3-5 stakeholders, surface their recent activity from the business-side `enrich-business --type linkedin-posts --session-id <sid> --table-name dm_map_accounts` instead (per-prospect linkedin-posts is not exposed).

8. Synthesize. Each retrieval is raw context. Decide what makes the map, framed by purpose, priority personas, and named hypotheses.
   - Events triage: keep new-hire, executive-move, and promotion signals at director-level and above, especially in the priority personas or adjacent functions. For each newly-named person, run `match-prospects` if not already enriched and add to the committee with a RECENTLY APPOINTED flag and the event date.
   - Role classification (conservative):
     - Champions require explicit engagement evidence (CRM activity, demo attended, prior emails). Title alone is never sufficient; without a signal, place under Influencers > Potential Champions.
     - Technical Evaluators are director-and-above in Engineering, IT, or the function being sold to.
     - Economic Buyers hold budget: C-Level Finance, the function head sponsoring the deal, or CEO for strategic deals.
     - Influencers use named sub-buckets (Procurement, Legal / Compliance, Operations, Adjacent Marketing, HR / Talent, Potential Champions). Skip empty buckets.
   - Hypothesis check: explicitly address each named hypothesis: confirmed, contradicted, or unresolved. Surface the answer in the TL;DR.
   - Source tagging: tag every contact with source: `[from fetch-entities]`, `[from events]`, `[from match-prospects]`.

9. Write the exec summary last. Re-read the body, then write the TL;DR at the top, framed by the map purpose.

## Output Format

### Decision-Makers Map: [Company Name]
**[linkedin_category or naics_category]** | **[headcount / company_size]** | **[revenue_range / company_revenue]** | **[HQ]**

### TL;DR
Map purpose: [restate the user's context in one line, or "general committee mapping for prospecting (no context supplied)" if defaulted].

One paragraph framed by the map purpose. Top 3 contacts to engage (named, one-line reasoning each, tied to the purpose), biggest coverage gap (specific role or function with risk), single-thread risk in one sentence, and a one-line answer to each named hypothesis (confirmed / contradicted / unresolved).

Sample preview phrasing for the committee tables: "Sample preview (top 20 of <total> matches from `fetch-entities-statistics`)."

### Company Snapshot
One paragraph: what they do, where they sit, key firmographic and strategic signals.

### Account Context
- Deal Status: stage, value, close date, competition (from user context).
- Engaged Stakeholders: who has already been contacted (from user context).
- Key Signals: leadership moves, funding, strategic shifts from `fetch-businesses-events` and `enrich-business`.
- Open Issues / Blockers: from user context.

### Committee Map (tables)
Per category, lead with a 5-column table. Skip empty categories.

#### Economic Buyers
| Name | Title | Email | Status | Source |
|------|-------|-------|--------|--------|

#### Champions
| Name | Title | Email | Status | Source |
|------|-------|-------|--------|--------|
(Explicit engagement evidence required. If none: "No Champions identified. See Potential Champions under Influencers.")

#### Technical Evaluators
| Name | Title | Email | Status | Source |
|------|-------|-------|--------|--------|

#### Influencers
Group by named sub-bucket (Procurement, Legal / Compliance, Operations, Adjacent Marketing, HR / Talent, Potential Champions). One 5-column table per bucket that has contacts.

#### Recently Appointed (last 90 days)
| Name | Title | Appointment Date | Email | Status |
|------|-------|------------------|-------|--------|
These also appear in their primary category with a RECENTLY APPOINTED flag.

### Key Stakeholders (top 3-5)
Richer profiles for the deep-researched contacts.

#### [Name]: [Title]
- Role: Economic Buyer / Champion / Technical Evaluator / Influencer:Sub-bucket
- Background: from `enrich-prospects profiles` (career summary, time in role).
- Engagement history: prior interactions from user context, or "No prior engagement recorded".
- Why they matter: tied to role and account context.
- Flags: `no email on file`, `RECENTLY APPOINTED`, source disagreements.
- Recommended approach: specific to the named hypothesis, current signal, or coverage need.

### Engagement Strategy
Specific to this account, not a generic playbook. Anchor each step to a named person and a real signal.
1. Immediate priorities (next 2 weeks): top 3 actions, each tied to a specific person and signal.
2. Coverage gaps: specific empty persona slots (e.g. "No Finance stakeholder below the CFO; director-level FP&A search recommended").
3. Sequencing: ordered outreach with named people and reasons.
4. Single-thread risk: current dependencies and the moves to fix them.

### Excluded / Needs Verification
| Name | Reason | Recommended Action |
|------|--------|--------------------|
Use for: prospects with no `email` and no `linkedin_url`, ambiguous title matches, or names returned only by events that `match-prospects` could not resolve. Do not include in the main map.

### Next Steps
Concrete next actions, each referencing a specific person, persona gap, hypothesis, or signal surfaced above, and tied to the map purpose.

## Limitations
- `strategic-insights` and `challenges` enrichments are sourced from SEC 10-K filings; for private companies these will be all-null, and for public companies the data can be 12-18 months stale. Use `fetch-businesses-events`, `funding-and-acquisitions`, `workforce-trends`, and `linkedin-posts` for current-state signals.
- No native contact data-quality sort. Use `has_email: true` as a proxy for reachable contacts.
- No sub-department job-function filter. Combine `job_title` autocomplete + `job_department` to approximate functions like "FP&A" or "SecOps".
- No CRM-engagement signal in the data surface. Champion designation depends on engagement evidence supplied in the user context; without it, default to Potential Champions under Influencers.
- Bucket-only company size and revenue. Use `company_size` and `company_revenue` buckets when describing the account snapshot.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in any By-Department breakdown rather than dropping them.
- Map raw `prospect_job_seniority_level` values to canonical filter values for display: `cxo` -> `c-suite`, `vp` -> `vice president`. Use the canonical value when describing seniority in committee categories.
