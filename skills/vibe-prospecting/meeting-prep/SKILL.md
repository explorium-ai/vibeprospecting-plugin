---
name: meeting-prep
description: Prepare for an upcoming sales meeting with a target account. Identify the company by Explorium business_id (preferred) or by company name or domain (which triggers a lookup step). Provide attendee names or emails and rich context on the meeting purpose, stakes, and known dynamics so the calling agent can synthesize a tight, decision-ready brief: headline, attendee profiles, ranked talking points, discovery questions, suggested agenda, and what NOT to do. Optimized for a 30-minute slot. Triggers on phrases like "prep me for a meeting with", "build a call brief for", "I have a call tomorrow with", "pre-meeting research on".
---

# Meeting Prep
Pull the company, signal, and attendee data the calling agent needs to write a tight, decision-ready brief for a ~30-minute meeting.

## Input
The user will provide:

- **Account identifier (required)**, one of:
  - **Preferred**: an Explorium `business_id` (UUID). Use directly; skip the resolve step.
  - **Fallback**: a company name or domain. Resolve via `match-business` as the first data step.
- **Attendees (recommended)**: names and/or email addresses. Without attendees the brief is necessarily generic.
- **Meeting context (strongly recommended)**: a free-form description of the meeting and what success looks like. Capture meeting purpose, stakes, prior discussions, deal stage, walk-out goals, known tensions, competitive context, the offering in play, hypotheses to test, and pitfalls to avoid. Flat enums like "discovery / QBR / renewal / demo" produce flat briefs; richer is better.

If the identifier is ambiguous: a string containing a dot or known TLD is a domain; otherwise treat it as a name.

## Workflow
Parallelize aggressively. Most enrichment calls only need the `business_id` and can fan out together. Per-attendee, run `enrich-prospects` for `contacts` and `profiles` in parallel so a structured fallback exists when the profile payload is thin.

1. **Anchor on purpose.** Read the meeting context from the user's message.
   - If supplied, restate it in 1-2 sentences as the meeting purpose and keep it as the framing lens for every downstream step.
   - If missing, ask the user once. If they decline or say "just general prep", default to general meeting prep and state that assumption at the top of the brief.
   - From the context, derive: a meeting purpose (1 line), the desired outcome (what walking out successful looks like), 3-5 priority topics or themes, and any named risks or hypotheses to test. These drive the strategic-insights focus, attendee framing, talking-point ranking, and the suggested agenda.

2. **Resolve the company.**
   - If a `business_id` was supplied, use it directly. Do not call `match-business`.
   - Otherwise call `match-business` with the company name or domain. Extract the top `business_id`. If no confident match, surface the ambiguity to the user before continuing rather than guessing.

3. **Open a working table for this account.** Pick a descriptive `--table-name` (for example `call_prep_<companyslug>_<yyyymmdd>`) and reuse the same `--session-id` for every enrich call so all enriched data lands in one table for synthesis.

4. **Fan out company enrichment in chunked calls (max 3 enrichments per call).** Treat each call as a context-retrieval step. Pull broadly now; decide what's relevant during synthesis. `enrich-business` accepts at most 3 enrichments per call, so chunk the 11 enrichments into 4 calls against the same `--session-id` and `--table-name`. Capture the new `table_name` returned by each call (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns.
   - Call 1: `[firmographics, technographics, webstack]` (industry / size / revenue / HQ, installed tech, detected web stack).
   - Call 2: `[funding-and-acquisitions, strategic-insights, challenges]` (rounds and M&A, stated priorities, pain themes).
   - Call 3: `[workforce-trends, competitive-landscape, company-hierarchies]` (hiring direction, named peers, parent/subsidiaries).
   - Call 4: `[linkedin-posts, website-changes]` (last 30-60 days voice and site movement).

5. **Pull recent business events.** Call `fetch-businesses-events --session-id <id> --table-name <prior_table>` (the table from step 3, which holds the resolved `business_id`) and scope to a recent window (last 30-90 days) via the events filter. Use the returned event types as-is. Treat events as raw signal to triage in step 7, not as a pre-filtered list.

6. **Resolve and enrich attendees in parallel.**
   - Use `match-prospects` to resolve each attendee, providing email when available, otherwise full_name plus the resolved `company_domain` (or `business_id`). If an attendee cannot be resolved, note it. Do not fabricate.
   - With the resolved `prospect_id` set, run `enrich-prospects --type contacts --contact-types email` and `enrich-prospects --type profiles` in parallel (batches of up to 50 prospect IDs per call). Cost is ~2 credits per row (email-only) vs ~5 credits per row (email + phone). Switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). If recent posting voice would change the opener, pull it from the business-side `enrich-business --type linkedin-posts --session-id <id> --table-name <prior_business_table>` (mentions of the prospect by their employer). There is no native per-prospect linkedin-posts enrichment.

7. **Hand back the raw evidence for synthesis.** The calling agent writes the narrative brief. Return the table contents from step 3 plus the events payload, organized so the calling agent can:
   - Triage events and posts: keep items that tie to the meeting purpose, deal stage, attendees, or priority topics. Drop generic press unrelated to the agenda.
   - Classify relationship posture per attendee from `profiles` employment history and recent posts: Cold, Warm-but-dormant (significant past tenure at a relevant prior employer with no current engagement, highest leverage), Active, or Hostile. The opener depends on this.
   - Rank 3-5 talking points by relevance to the desired outcome. Each must tie to a specific surfaced fact and, where possible, a named attendee.
   - Hypothesis check: explicitly address each named hypothesis or risk from step 1 as confirmed, contradicted, or unresolved.
   - Tag key claims with their source: `[firmographics]`, `[technographics]`, `[strategic-insights]`, `[challenges]`, `[workforce-trends]`, `[competitive-landscape]`, `[linkedin-posts]`, `[website-changes]`, `[funding-and-acquisitions]`, `[hierarchies]`, `[events]`, `[contacts]`, `[profiles]`. When the profile payload is thin, mark the attendee with a confidence note.
   - Past-date flag: for any date returned by enrichment or events that is in the past relative to today, retain it and flag for verification rather than dropping silently.

8. **Synthesis prompt for the calling agent.** Write the TL;DR last, after the rest is drafted. Frame it explicitly by the meeting purpose and desired outcome.

## Output Format
Return the enriched table reference plus a structured synthesis the calling agent fills in.

### TL;DR
> **Meeting purpose / desired outcome**: [restate in one line, or "general meeting prep (no context supplied)" if defaulted].
>
> **Top 3 to know walking in** (each tied to the desired outcome):
> 1. [Most decision-relevant fact]
> 2. [Second]
> 3. [Third]
>
> **Hypothesis check** (one line per named hypothesis from the input): confirmed / contradicted / unresolved.
>
> **Open with**: "[Single recommended opening line, verbatim, calibrated to attendee posture]"

### Company Snapshot
| Field | Value |
|-------|-------|
| Industry (linkedin_category / naics_category) | |
| Company size bucket | |
| Revenue range | |
| HQ | |
| Website (company_domain) | |
| Business model | |

One-paragraph overview from the firmographics description, with strategic priorities and current challenges woven in.

### Signals Worth Raising
Group surfaced items by category. Keep what maps to meeting purpose or attendees; drop noise.

- **Funding and M&A** `[funding-and-acquisitions]`
- **Hiring direction** `[workforce-trends]`
- **Tech stack overlap or gaps** `[technographics][webstack]`
- **Recent business events** `[events]`
- **Voice on LinkedIn or site changes** `[linkedin-posts][website-changes]`
- **Competitive context** `[competitive-landscape]`
- **Parent / subsidiary context** `[hierarchies]`

For any past date inline: *"Verify; date is in the past, may indicate active negotiation, stale signal, or missed milestone."*

### Attendees
For each attendee:

#### [full_name], [job_title]
| Field | Value |
|-------|-------|
| job_department | (fallback "Unattributed" when null) |
| job_level | (display canonical: `cxo` -> `c-suite`, `vp` -> `vice president`) |
| professional_email | |
| phone_number | |
| linkedin_url | |
| Time in role | |
| Posture | Cold / Warm-but-dormant / Active / Hostile |

**Why they matter for THIS meeting**: 2 lines max. Connect role and background to the decision in front of them.

**Talking points for them**: 1-2 specific to this attendee.

If the profile payload is thin, add: *"Profile data restricted; verify externally."*

### Talking Points (3-5)
Ranked by impact, each tagged for its audience.

1. **[Topic]** `[for: <attendee names or "all">]`: [Why to raise it + supporting data point with source tag]
2. ...

Prioritize items that show homework, connect to your offering, surface competitive angles, or hit a specific persona.

### Discovery Questions (3-5)
Specific, anchored in concrete facts from the brief, not generic.

1. **[for: <attendee or "group">]**: [Question grounded in something surfaced above.]
2. ...

### Suggested Agenda (~30 min)
- **(0-5) Open**: [Specific opener; relationship-continuity for warm-dormant, value-frame for cold, status-check for active]
- **(5-15) Explore**: [Primary discovery thread; top talking point + 2 questions]
- **(15-25) Develop**: [Second thread; secondary point, demo, or proposal]
- **(25-30) Close**: [Specific desired next step]

### What NOT to Do
1-3 specific failure modes for THIS meeting. Concrete, not generic.

- **Don't [specific anti-pattern]**: [why it would backfire here].

## Limitations
- `strategic-insights` and `challenges` enrichments are sourced from SEC 10-K filings; for private companies these will be all-null, and for public companies the data can be 12-18 months stale. Use `fetch-businesses-events`, `funding-and-acquisitions`, `workforce-trends`, and `linkedin-posts` for current-state signals.
- `fetch-businesses-events` `timestamp_from` is a date floor; no upper bound is supported in the schema.
- Company size and revenue are bucketed, not exact. State buckets verbatim; do not interpolate a precise headcount or revenue figure.
- No native CRM relationship history or deal-stage data. Posture must be inferred from `profiles` employment history and `linkedin-posts` voice, supplemented by whatever context the user supplied.
- Past-date flags must be verified externally. Enrichment may surface stale signals; treat any past-dated milestone as a prompt to check, not as ground truth.
- Attendees whose emails or names cannot be resolved by `match-prospects` should be listed as unresolved. Do not synthesize their roles.
- `job_department` is null for many cross-functional senior roles (Chief X Officer, President, Founder). Group these under "Unattributed" in any By-Department breakdown rather than dropping them.
- Raw `prospect_job_seniority_level` values like `cxo` and `vp` should be mapped to canonical filter values for display: `cxo` -> `c-suite`, `vp` -> `vice president`.
