---
name: account-contact-shortlist
description: Build a ranked shortlist of contacts at a target company for prospecting, deal acceleration, or renewal/expansion plays. Provide a company name or domain and optionally a use case or seniority focus.
---

# Account Contact Shortlist
Pull the right people at a target account and rank them for outreach, with a use-case lens (new business, active deal, renewal) and a reachability check.

## Input
The user provides:
- A company name or domain (required).
- Optional use case: "prospecting" (default), "deal acceleration", or "renewal" / "expansion".
- Optional seniority focus (C-level, VP+, Director+) or a specific function (sales, marketing, RevOps, security, finance).
- Optional size of the shortlist (default 25, max 100).

## Workflow

1. Resolve the company. `match-business` returns one winner with no runner-up candidates — there is no "top-N matches" mode. Work around this with two concrete rules:
   (a) **Bare common-name tokens require domain confirmation upfront.** If input is a single common-noun word with no domain and no LinkedIn URL ("Apex", "Delta", "Northwestern"), do NOT call match-business yet — ask the user for a domain, or if the user provided industry/size hints, run a `fetch-entities` businesses query filtered by those hints and present the top candidates from THAT for confirmation.
   (b) **Firmographic sanity check after every match.** If the resolved record's industry, headcount, or revenue is wildly off from any user hint, surface the mismatch explicitly ("Resolved 'Apex' to Apex Systems — IT services, VA, 10001+. Is that the one you meant?") before proceeding. Shell-entity case (1-50 employees in Corporate-Managing-Offices category for a known major-brand input): retry with the alternate domain or `{name, domain}` together before flagging as failed.

   **Over-cap rule:** if the user requested more than 100 contacts, return 100 with a one-line note ("Requested N, capped at 100 per workflow limit. Use `exclude_key` to fetch the next batch."). Never silently truncate.

2. Enrich the resolved business with firmographics to anchor the output header (industry, size bucket, revenue bucket, HQ, public vs private).

3. Translate the use case into a persona blueprint before any prospect fetch. Prospecting / default: broad buying-committee coverage across Sales, Marketing, RevOps, IT, and Product, weighted toward Director, VP, and C-level. Deal acceleration: economic buyer plus technical evaluator plus procurement, biased to C-level and VP in the relevant function, plus one Director-level champion. Renewal / expansion: existing product-owner functions plus an executive sponsor, including Manager and Director levels alongside VP+. Intersect any user-supplied seniority or function override with the blueprint and note dropped roles.

4. Discover canonical values for every free-text role or industry token before filtering. Combine a job-title filter with an explicit seniority constraint to keep matches tight: a title-only filter for "Vice President of Engineering" leaks non-VP rows, so intersect title with seniority.

   **Null-seniority handling.** Many senior contacts have `prospect_job_seniority_level: null` — and the filter constraint excludes only non-matching values, not nulls, so null-seniority rows bypass a tight VP+ or Director+ filter and leak IC/manager noise into the shortlist. When the user's seniority constraint is tight, apply a secondary **title-pattern check** against `prospect_job_title` before keeping any null-seniority row: keep the row only if the title contains one of `chief `, `vice president`, `vp `, `head of`, `director`, `evp`, `svp`, `president` (case-insensitive). Drop rows where neither the seniority field nor the title pattern proves the level.

5. Sample 5 prospects scoped to the resolved account, matching the blueprint's titles, seniority, and department, with a reachability proxy (has-email true). Present this preview for the user to sanity-check the persona translation and wait for approval before going full size. When the user names a role rather than a person ("the CFO at Notion"), do not try to resolve a title string as a person; surface candidates via the filtered prospect fetch instead.

6. After approval, materialize the full shortlist and enrich prospects for contact data. Default to email-only contact enrichment because it is the cheaper option; opt in to phone only when the user explicitly needs dialer-ready output. **Pull profile enrichment on every contact before naming, not just the top 10**, so tenure can gate inclusion (not just feed the ranking rationale).

   **Current-employment gate (mandatory).** The `business_id` filter on prospect searches returns people *associated* with the company — alumni, board members, investors, and franchisees can leak through. Before any contact is named or ranked in the shortlist, check the profile's experience history: if the prospect's *most recent* experience entry is not the target account, drop the row (or route to "Needs Verification" with reason `tenure unconfirmed`). Additional rule: if `prospect_job_title` is a generic-affiliation string (`Shareholder`, `Investor`, `Member`, `Affiliate`) AND `firmo_naics` is a holding-company or franchise category, drop the row unconditionally — these are not employees.

7. Rank and group. Score each contact on persona fit (title and department match, weighted by seniority), reachability (professional email, then personal email, then phone), and tenure or stability from the profile pull (recent joiners get a small bump for prospecting, a penalty for renewal). Break ties by seniority.

## Output Format

### Target Account
One line: company name, domain, industry, headcount bucket, revenue bucket, HQ, public vs private.

### Use Case Frame
State the resolved use case and what the shortlist optimizes for (prospecting = buying-committee coverage on a first conversation; deal acceleration = economic buyer plus technical evaluator plus procurement plus a Director-level champion; renewal / expansion = current product owners plus an executive sponsor). List any user-provided overrides that narrowed the blueprint.

### Shortlist

| Rank | Full Name | Job Title | Seniority | Department | Professional Email | Phone | LinkedIn | Why On The List |
|------|-----------|-----------|-----------|------------|--------------------|-------|----------|-----------------|

"Why On The List" is one short clause referencing the persona-blueprint slot the contact fills (e.g. "VP-level economic buyer in Sales"). Show "Unattributed" in the Department column for cross-functional senior roles where department is null.

### Coverage Read
Counts by department, by seniority band, and by reachability (professional email, personal email only, phone, none). Flag gaps where the use case expected a slot but no contact was found (e.g. "No procurement contact surfaced for deal acceleration").

### Engagement Priority
Pick the top 5 to contact first with a one-line reason each, distinguishing entry points (Manager / Director with strong reachability) from decision makers (VP / CXO in the relevant function). Suggest an outreach order.

### Next Steps
- Brief the opener with fresh account context via funding, challenges, or strategic-insights enrichments.
- Fetch prospect events on the shortlist to catch recent role changes or new-hire signals before the first touch.
- Re-run with a different use case to compare the buying committee against an in-flight deal team.

## Limitations
- No native contact data-quality sort. Reachability is approximated from the has-email flag plus enriched professional email and phone.
- Headcount and revenue are bucketed, so very narrow size cutoffs are not possible.
- No sub-department job-function filter. The finest cut on function is department plus title.
- The only company-type filter is public vs private. Private subsidiary cannot be distinguished from independent private.
- Department is null for many cross-functional senior roles. Group those under "Unattributed" rather than dropping them.
- Sample previews are capped at 5 rows. Full shortlists materialize only after user approval.
- `business_id` on prospect searches returns *associated* people, not currently-employed — alumni, board members, investors, and franchisees can leak through. The current-employment gate in Workflow step 6 is mandatory: every contact's most-recent experience entry must be the target account before they reach the shortlist. Generic-affiliation titles (`Shareholder`, `Investor`) at holding-company NAICS codes are dropped unconditionally.
- `match-business` returns one winner with no runner-up candidates or confidence score. "Show top 2-3 matches" is not API-supported. Workflow step 1 substitutes a domain-confirmation + firmographic-sanity-check pattern.
- Many senior contacts have null `prospect_job_seniority_level`. Null-seniority rows bypass tight `job_level` filters; the title-pattern fallback in step 4 is required to enforce VP+ / Director+ cuts.
- Shortlist size hard-caps at 100. Over-cap requests return 100 with an explicit note; never silently truncated.
