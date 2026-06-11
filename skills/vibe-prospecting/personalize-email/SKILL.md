---
name: personalize-email
description: Assemble a personalization signal pack for one prospect so a downstream LLM can compose a tailored email. Resolves the prospect, pulls company firmographics + recent business events + funding + workforce trends + LinkedIn posts + website changes + intent topics, and attaches the prospect's role context and LinkedIn activity. Returns a structured brief (signal ladder, recency stamps, anchor candidates, persona cues, proof hooks) ready to drop into a cold outbound, follow-up, re-engagement, renewal, expansion, or objection-handling email prompt. Use for sales prospecting, lead generation, account-based selling, signal-led outreach, B2B prospecting. Triggers on phrases like "personalize an email", "draft outreach", "outbound to X", "follow up on this prospect", "find a hook for this contact", "build me a personalization brief", "what should I say to this lead".
---

# Personalize Email

Gather every personalization signal for a single prospect and their company so the calling model can write a sharp, specific email.

## Input

- Prospect identifier (required): full name + company OR full name + company domain OR LinkedIn URL OR email.
- Use case (default `cold_outbound`): one of `cold_outbound`, `discovery_follow_up`, `demo_recap`, `re_engagement`, `renewal`, `expansion`, `objection_handling`. Drives which signals matter most.
- Recency floor (optional): days. Defaults: 14 for intent topics, 30 for executive moves, 90 for company events.
- Sender / offering note (optional): one line on what the user sells, used only to rank signals; never sent to a model that drafts the email here.
- Prior touchpoint summary (optional, recommended for follow-ups, recaps, renewals): what was last discussed, when, who was involved.

This skill does NOT draft the email. It returns a structured brief; the calling model composes copy from it.

## Workflow

1. Resolve the prospect.
   - If LinkedIn URL or email is supplied, call `match-prospects` with that identifier.
   - Otherwise call `match-business` first on the company name or domain to get a `business_id`, then call `match-prospects` with `full_name` plus the resolved `business_id` (or `company_domain` passed to `match-prospects`).
   - On miss, retry `match-prospects` with first+last instead of full name and the resolved `business_id`. Identity fields (`full_name`, `first_name`, `last_name`, `company_name`, `company_domain`) are inputs to `match-business` / `match-prospects`, never filters on `fetch-entities`.
   - Resolve-by-role path (no name supplied, e.g. "CFO at Notion", "CISO at Salesforce"): `match-prospects` with `full_name="CFO"` returns 0 silently and is the wrong path. Instead call `fetch-entities` with `entity_type: prospects`, `--businesses-table-name <match_business_table>`, and a `job_title` filter (autocomplete-resolved) plus `job_level` filter. This is the dominant cold-outbound use case when the user knows the seat but not the person.
   - Capture `prospect_id`, `business_id`, `full_name`, `job_title`, `linkedin_url`. If no `prospect_id` or no `business_id` resolves, stop and surface the gap. Sanity check after firmographics lands in step 3: if the resolved business_id's firmographics show a major-brand input but headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity. Re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id.

2. Confirm autocomplete-gated values before any filtered company pull.
   - If the user named an industry, run `autocomplete linkedin_category` (or `naics_category` when they used a NAICS label) and show top 3 to 5 matches.
   - If they named a city, run `autocomplete city_region`.
   - Wait for the user to pick before filtering. Use `company_country_code` directly with no autocomplete.

3. Pull firmographics for the company.
   - Create a session id (capture as `<sid>`) and seed a businesses table (e.g. `outreach_company`) from the step-1 `match-business` resolution.
   - Call `enrich-business --session-id <sid> --table-name outreach_company --type firmographics`. Capture `company_name`, `company_domain`, `linkedin_category`, `company_size`, `headcount`, `company_revenue`, `revenue_range`, headquarters location, company_age.

4. Pull recent company signals in chunked calls (max 3 enrichments per call).
   - Reuse the same `--session-id <sid>` and pass `--table-name outreach_company` on the first call. `enrich-business` accepts at most 3 enrichments per call. Capture the new `table_name` returned by each call (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns.
   - Call 1: `enrich-business --session-id <sid> --table-name outreach_company --type funding-and-acquisitions workforce-trends linkedin-posts` (rounds/M&A/IPO chatter, hiring surges/layoffs/department growth, recent posts).
   - Call 2: `enrich-business --session-id <sid> --table-name <view_from_call_1> --type website-changes challenges strategic-insights` (new product pages/pricing/careers, stated challenges, stated priorities).
   - Call 3 (conditional): `enrich-business --session-id <sid> --table-name <view_from_call_2> --type technographics competitive-landscape` - `technographics` only if the offering note implies a tech-stack-relevant pitch; `competitive-landscape` only when the use case is `objection_handling` or the offering note flags a competitive displacement.
   - `fetch-businesses-events --session-id <sid> --table-name <latest_view>` and scope the events filter to the last 90 days. Keep every event with a date; drop ones older than the recency floor for the use case.

5. Pull the prospect's own context. Seed a prospect-side table (e.g. `outreach_prospect`) from the `match-prospects` step in step 1; every call below must spell out `--session-id <sid> --table-name outreach_prospect`.
   - `enrich-prospects --session-id <sid> --table-name outreach_prospect --type profiles` to get seniority, department, tenure, prior roles.
   - Prospect-side recent posts are not available via enrich-prospects. Pull `enrich-business --session-id <sid> --table-name outreach_company --type linkedin-posts` instead for the employer's recent voice; for the individual prospect's posting voice, document this as a current gap.
   - `enrich-prospects --session-id <sid> --table-name outreach_prospect --type contacts --contact-types email` only when the user intends to send the email and needs `email`. Cost is ~2 credits per row (email-only) vs ~5 credits per row (email + phone). Switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). Skip the call entirely otherwise.
   - `fetch-prospects-events --session-id <sid> --table-name outreach_prospect` for job-change or promotion events on this person.

6. Score and rank the signals.
   - Stamp every signal with age in days and a source tag (event, post, funding round, website change, intent topic, role change).
   - Score `recency_weight` x `persona_relevance` x `use_case_fit`:
     - Recency: 0 to 14d = 1.0, 15 to 30d = 0.7, 31 to 60d = 0.4, 61 to 90d = 0.2, older = drop.
     - Persona relevance: CFO maps to funding / earnings / M&A; CRO and VP Sales map to hiring surges, product launches, go-to-market posts; CTO and VP Eng map to website changes, technographics, engineering hires; CEO maps to all.
     - Use case fit: `cold_outbound` and `re_engagement` lean on fresh external events; `discovery_follow_up`, `demo_recap`, `renewal`, `expansion` lean on the prior touchpoint plus role / company posts; `objection_handling` leans on competitive-landscape and strategic-insights.
   - Rank top 5. Mark the highest as `anchor_candidate`; next as `runner_up`.

7. Build the persona cue block.
   - From the profile pull: seniority, department, tenure in seat, prior employers (last 2).
   - Tone hint by seat: executive (outcome first, numeric), director or manager (problem then approach then outcome), IC (workflow friction then concrete benefit).
   - Pull 1 to 3 direct quotes or themes from the prospect's recent posts when available.

8. Assemble the proof hook list.
   - Pull company peers from `linkedin_category` + `company_size` band as candidate look-alike framings. Do not invent customer names or stats. Only flag categories where the calling model could later plug in real customer proof from the user's own materials.

9. Flag gaps and refuse conditions.
   - If `cold_outbound` or `re_engagement` and zero events pass the recency floor and zero relevant prospect posts exist, mark `signal_layer: thin` and recommend the user warm via another channel before sending.
   - If `discovery_follow_up`, `demo_recap`, or `renewal` and no prior touchpoint summary was supplied, surface the gap and ask the user for the summary; do not fabricate one.
   - If the prospect's profile last update is older than 12 months or the resolved `company_name` does not match the user-named company, add `stale_record: true` and recommend verifying role.

## Output Format

### TL;DR
One paragraph: prospect name, title, company, the single strongest anchor signal with age, and the persona-tone hint.

### Prospect
| Field | Value |
|---|---|
| Full name | ... |
| Job title | ... |
| Company name | ... |
| Company domain | ... |
| LinkedIn URL | ... |
| prospect_id | ... |
| business_id | ... |
| Email | ... (only if `enrich-prospects --type contacts --contact-types email` was called) |

### Company snapshot
Two to four lines covering `linkedin_category`, `company_size` bucket, `headcount`, `revenue_range`, headquarters, founding year.

### Signal ladder (ranked)
For each of the top 5:
- Rank, signal type, age in days, source tag.
- One-line description.
- Why it matters for this persona and use case.
- Anchor candidate / runner-up flag.

### Persona cues
- Seniority, department, tenure in seat.
- Prior employers (last 2).
- Tone hint.
- Direct quotes or post themes (up to 3, with date).

### Proof hook categories
List of peer-segment framings the calling model could plug real customer proof into. No invented stats, no invented logos.

### Brief for the drafting model
A compact JSON-shaped block the calling model can read:
```
{
  "anchor": "<signal type> (<age>d)",
  "runner_up": "<signal type> (<age>d)",
  "persona": { "seniority": "...", "department": "...", "tone": "..." },
  "company": { "name": "...", "size": "...", "industry": "..." },
  "use_case": "<chosen use case>",
  "gaps": ["..."],
  "do_not_invent": ["customer names", "stats not in this brief"]
}
```

### Flags
- `signal_layer`: rich | moderate | thin.
- `stale_record`: true | false.
- `missing_prior_touchpoint`: true | false (only set for follow-up family use cases).
- `competitor_mention_detected`: true | false (from competitive-landscape pull).

## Limitations

- `funding-and-acquisitions` enrichment has coverage gaps for late-stage privates that haven't filed an S-1. Notion returned all-null funding fields despite being a well-known ~$10B+ valuation. For CFO personas at private targets, lean on `fetch-businesses-events` (merger_and_acquisitions, new_funding_round, cost_cutting, hiring_in_finance_department) instead.
- No sort by signal recency at the API level; ranking is done client-side after pulling events.
- No metro taxonomy; location filtering relies on `city_region` (autocomplete) plus `company_country_code` only.
- No similar-companies tool; peer framing falls back to `linkedin_category` + `company_size` band.
- Headcount and revenue come as buckets, not exact values.
- This skill does not draft email copy. The calling model writes subject lines and bodies from the brief.
- Per-prospect linkedin-posts is not available; surface this as a gap when the use case wants the individual prospect's posting voice.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in the persona cue block rather than dropping them.
- Map raw `prospect_job_seniority_level` values to canonical filter values for display: `cxo` -> `c-suite`, `vp` -> `vice president`.
