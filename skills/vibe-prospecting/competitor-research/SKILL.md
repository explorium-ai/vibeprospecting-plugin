---
name: competitor-research
description: Build a fact-led competitive intelligence brief on one or more rival companies. Use when the user says "competitor analysis", "size up a competitor", "compare rivals", "competitive landscape", "vendor battlecard", "rival snapshot", "track competitor moves", or asks for a side-by-side comparison of named companies with firmographics, funding, headcount, exec roster, hiring shifts, tech stack, and recent strategic moves.
---

# Competitor Research
Produce a dated, source-tagged competitive brief for one or more named rival companies using Explorium firmographics, strategic insights, funding history, workforce trends, and exec rosters.

## Input
- One or more competitor company names or domains (required).
- Optional brief purpose (e.g. "battlecard for renewal", "board update", "win-loss prep"). If absent, ask once for it before running the workflow so the synthesis stays grounded.
- Optional priority angles (e.g. "pricing pressure", "AI roadmap", "EMEA expansion").
- Optional named hypotheses to confirm or contradict.

## Workflow
1. Anchor on purpose. Restate the brief purpose, priority angles, and hypotheses in 1-2 sentences before any tool call so the downstream synthesis stays scoped.

2. Resolve each competitor to a business_id with `match-business` (pass name + domain when available). `match-business` returns only `business_id` (and the input echo); firmographics require a separate `enrich-business --type firmographics` call (see step 3). If the resolved business_id's firmographics show a major-brand input but headcount is 1-50 and NAICS is `551114` (Corporate Managing Offices) or SIC is `Hotels and motels`, the match likely routed to a registered-agent shell entity; re-try with the alternate domain (.so vs .com) or with the company name string. Do not proceed with the wrong business_id. Skip any name that does not resolve and flag it under data quality.

3. For each resolved competitor, call `enrich-business` with `--all-parameters` and `--tool-reasoning`, passing `--session-id` and `--table-name`. `enrich-business` accepts at most 3 enrichments per call, so chunk the 9 enrichments into 3 calls. Capture the new `table_name` returned by each call (a fresh `view_<hash>`); thread THAT new table forward into the next enrich/events/export call, NOT the original `match-business` table. Each enrich call produces a new view table; the original fetch/match table does not get the enrichment columns. The CLI batches 50, so a handful of competitors runs in one pass.
   - Call 1: `[firmographics, competitive-landscape, strategic-insights]` (HQ/headcount/revenue/founded, named competitors, priorities and recent moves).
   - Call 2: `[funding-and-acquisitions, workforce-trends, technographics]` (rounds and M&A, headcount trajectory, current tech stack).
   - Call 3: `[challenges, company-ratings, linkedin-posts]` (publicly surfaced risks, third-party ratings, recent owned-channel narrative).

4. Pull recent business events with `fetch-businesses-events --session-id <sid> --table-name <rivals_table>` (the working businesses table from step 3 holds every resolved business_id). Keep events from the last 90 days that map to: product launches, leadership changes (vice president and above), funding rounds, M&A, office openings or closures, and material hiring shifts. Discard the rest. Event attribution sanity check: before including any `fetch-businesses-events` row in the brief, verify the event title/snippet actually mentions the target company name. Industry-wide articles can be cross-attributed to multiple competitors' business_ids in the data ingestion.

5. Surface the executive team per competitor with `fetch-entities` on `prospects`, scoped via `--businesses-table-name` to the working table, filtered by `job_level` to C-level and VP. Run `fetch-entities-statistics` first with the same filters to capture the total exec headcount per company. Sample-preview five rows per competitor before any bulk pull.

6. If the user asks for outreach-ready contacts on a specific exec subset, enrich with `enrich-prospects --type contacts --contact-types email` then `--type profiles`, passing `--session-id` and `--table-name`. Cost is ~2 credits per row (email-only) vs ~5 credits per row (email + phone). Switch to `--contact-types email phone` only when phone numbers are required (e.g. SDR dialer flows). Use `has_email: true` as a contact-quality proxy when filtering.

7. Classify ICP overlap per competitor (High / Partial / None) using firmographics versus the user's stated ICP. If the user has not stated an ICP, mark overlap as "Not assessed" rather than guessing.

8. Address each named hypothesis explicitly as confirmed, contradicted, or unresolved, citing the specific Explorium fields or events that drove the call.

9. Final delivery: write the working table to `--csv` only as the last step (exec roster + key firmographic columns); keep all intermediate previews on screen.

## Output Format
### Executive Comparison
- Purpose statement (one sentence) and hypothesis check (confirmed / contradicted / unresolved per item).
- Side-by-side table across all resolved competitors with columns: company_name, company_domain, HQ, headcount, company_size bucket, company_revenue bucket, founded year, public/private, CEO or top exec, last funding event, last strategic move (dated), competitive products noted.
- 90-day move highlights: dated bullets per competitor, source-tagged to the Explorium enrichment that surfaced them (e.g. `strategic-insights`, `funding-and-acquisitions`, `fetch-businesses-events`).
- Data quality flags: unresolved names, empty enrichments, stale records, contradictions between enrichments.

### Per-Competitor Section
Repeat per resolved competitor:
- Snapshot: HQ, headcount, revenue range, founded, public/private, primary tech stack signals.
- Recent moves (last 90 days): dated bullets, each tagged with the Explorium source.
- Strategic positioning: pulled verbatim from `strategic-insights` and `competitive-landscape` where present. Do not paraphrase.
- Workforce trajectory: direction and magnitude from `workforce-trends`.
- Challenges: bullets from `challenges`, dated where available.
- Funding and M&A: latest round, investors, any acquisitions or divestitures.
- Exec roster preview: Sample preview (5 of <total> matches) from step 5, with columns full_name, job_title, linkedin_url, professional_email (if enriched). If totals were not captured, use: "Sample preview (5 rows). Explorium has many more matching these filters."
- ICP overlap: High / Partial / None / Not assessed, with the firmographic evidence in one line.
- Three discovery questions rooted in specific surfaced facts (not generic).

## Limitations
- `competitive_10k_*` fields gate on SEC 10-K filings - populated for public competitors, null for private ones. Use NAICS + linkedin_category + technographics overlap for private targets.
- No native sort by employee count, revenue, or contact data quality. Contact-quality is approximated with `has_email: true`.
- Employee count and revenue are bucketed, not raw integers. Side-by-side comparisons use bucket labels.
- No similar-companies tool. If the user asks for adjacent rivals beyond named inputs, approximate by running `match-business` on `competitive-landscape` outputs, then re-enriching, and flag the approach explicitly.
- No metropolitan-area taxonomy. Geographic comparisons use country (ISO-2) or region (ISO 3166-2).
- `is_public_company` is the only company-type filter; finer ownership structure is not available.
- Sentiment from G2, TrustRadius, or earnings transcripts is not part of the Explorium surface and is out of scope for this brief.
