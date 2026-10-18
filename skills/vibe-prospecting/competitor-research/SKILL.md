---
name: competitor-research
description: Build a fact-led competitive intelligence brief on one or more rival companies. Use when the user says "competitor analysis", "size up a competitor", "compare rivals", "competitive landscape", "vendor battlecard", "rival snapshot", "track competitor moves", or asks for a side-by-side comparison of named companies with firmographics, funding, headcount, exec roster, hiring shifts, tech stack, and recent strategic moves.
---

# Competitor Research
Produce a dated, source-tagged competitive brief for one or more named rival companies.

## Input
- One or more competitor company names or domains (required).
- Optional brief purpose (e.g. "battlecard for renewal", "board update", "win-loss prep"). If absent, ask once before running so the synthesis stays grounded.
- Optional priority angles (e.g. "pricing pressure", "AI roadmap", "EMEA expansion").
- Optional named hypotheses to confirm or contradict.

## Workflow
1. Anchor on purpose. Restate the brief purpose, priority angles, and hypotheses in 1-2 sentences before any tool call so synthesis stays scoped.

2. Resolve each competitor: **match a business** by name + domain when available. Domain-variant sanity check: if a major-brand input resolves to a tiny headcount with a "Corporate Managing Offices" or "Hotels and motels" classification, the match likely routed to a registered-agent shell entity. Re-try with the alternate domain or with the company-name string. Do not proceed with the wrong identity. Skip any name that does not resolve confidently and flag it under data quality. **Drop rows with null `business_id` from the enrichment table before step 3** — track them in a data-quality flag list, but never pay to enrich rows that didn't resolve.

2.5. **Identity verification before deep enrichment.** Domain ≠ identity. Multi-tenant brand names (Apollo, Coda, Notion, Palantir) commonly route to namesake companies in adjacent verticals. After every match, run ONLY `enrich-business-firmographics` (1 credit/row) FIRST and verify:
   (a) `firmo_name` is string-similar to the input name,
   (b) `firmo_website` host-matches the input domain when domain was provided,
   (c) headcount bucket is plausible for a known brand (e.g. Notion ≠ 1-10 employees, Apollo.io ≠ 501-1000 cybersecurity in Cupertino),
   (d) LinkedIn URL slug aligns with the expected company.
   If ANY check fails, re-match with alternates (alternate TLD, `Inc`/`Labs` suffix, parent-company name, or `{name, domain}` together) BEFORE paying for 2-credit 10-K enrichments. The current 10-K and strategic-landscape enrichment defaults are the most expensive way to discover you matched the wrong company.

3. Enrich each resolved (and identity-verified) competitor in two tiers. **Tier A (always run):** firmographics (1 cr/row), workforce-trends, funding-and-acquisitions, technographics, LinkedIn posts. **Tier B (conditional — only when `firmo_ticker` is non-null, i.e. the company is public):** strategic-insights, competitive-landscape, challenges. These are 10-K-derived and bill 2 credits/row but return NULL for every private company. Skipping them on private targets is a hard rule, not a suggestion. For private competitors, lean on the Tier A bundle plus business events as the qualitative substitute. Company-ratings is optional — request only when the user explicitly asks for third-party signals.

4. Fetch business events for the resolved set, scoped to the last 90 days. Keep events that map to: product launches, leadership changes at vice president and above, funding rounds, M&A, office openings or closures, and material hiring shifts. Discard the rest. **Event-attribution sanity check (non-optional):** before including any event row in the brief, verify the event title or snippet contains a substring of the resolved `firmo_name` (or a documented brand alias). Industry-wide articles can be cross-attributed to multiple competitors' identities in the ingestion pipeline; if the target name doesn't appear in title or snippet, drop the row — do not let it anchor a "recent move" bullet.

   **Sub-country geography fallback.** When the user asks for a metro / city / sub-state breakdown ("Compare hiring across SF Bay Area vs NYC vs Austin"), the businesses endpoints only return country-level location distribution. Redirect to `fetch-entities-statistics` with `entity_type=prospects`, `business_id` filter, and either `city_region` (US cities only, requires autocomplete) or `prospect_region_country_code` (ISO 3166-2 state level). Headcount-by-metro is then *approximated by prospect-count-by-city*, not by office distribution. State the approximation explicitly in the output rather than silently shrugging at the request.

5. Surface the executive team per competitor: size the audience first (count of C-level and VP roles per company), then sample a small slice for preview. Run a count before any larger pull so you can frame the sample honestly.

6. If the user asks for outreach-ready contacts on a specific exec subset, enrich those prospects with contacts and profiles. Default to email-only contacts: it costs less than email + phone, and phone numbers are only needed for SDR dialer flows. Use presence-of-email as the contact-quality proxy when filtering.

7. Classify ICP overlap per competitor (High / Partial / None) using firmographics versus the user's stated ICP. If no ICP was stated, mark overlap as "Not assessed" rather than guessing.

8. Address each named hypothesis explicitly as confirmed, contradicted, or unresolved, citing the specific enrichment or event row that drove the call.

9. Final delivery: write the working table out only as the last step (exec roster + key firmographic columns); keep all intermediate previews on screen.

## Output Format
### Executive Comparison
- Purpose statement (one sentence) and hypothesis check (confirmed / contradicted / unresolved per item).
- Side-by-side table across all resolved competitors with columns: company name, domain, HQ, headcount, size bucket, revenue bucket, founded year, public/private, CEO or top exec, last funding event, last strategic move (dated), competitive products noted.
- 90-day move highlights: dated bullets per competitor, source-tagged to the enrichment that surfaced them (strategic insights, funding, business events).
- Data quality flags: unresolved names, empty enrichments, stale records, contradictions between enrichments.

### Per-Competitor Section
Repeat per resolved competitor:
- Snapshot: HQ, headcount, revenue range, founded, public/private, primary tech-stack signals.
- Recent moves (last 90 days): dated bullets, each tagged with the enrichment source.
- Strategic positioning: pulled verbatim from strategic-insights and competitive-landscape where present. Do not paraphrase.
- Workforce trajectory: direction and magnitude.
- Challenges: bullets, dated where available.
- Funding and M&A: latest round, investors, any acquisitions or divestitures.
- Exec roster preview: sampled rows with full name, job title, LinkedIn URL, professional email (if enriched). Frame as "Sample preview (5 of <total> matches)." If totals were not captured, use "Sample preview (5 rows). Many more match these filters."
- ICP overlap: High / Partial / None / Not assessed, with the firmographic evidence in one line.
- Three discovery questions rooted in specific surfaced facts (not generic).

## Limitations
- Strategic-insights and challenges are gated on SEC 10-K filings: populated for public competitors, null for private ones, and can be 12-18 months stale even when present. Use NAICS + LinkedIn category + technographics overlap for private targets.
- No native sort by employee count, revenue, or contact data quality. Contact quality is approximated by presence-of-email.
- Employee count and revenue are bucketed, not raw integers. Side-by-side comparisons use bucket labels.
- No similar-companies tool. For adjacent rivals beyond named inputs, approximate by resolving competitive-landscape outputs and re-enriching them, and flag the approach explicitly.
- No metropolitan-area taxonomy. Geographic comparisons use country (ISO-2) or region (ISO 3166-2).
- Only public/private as a company-type filter; finer ownership structure is not available.
- Sentiment from G2, TrustRadius, or earnings transcripts is not in the data surface and is out of scope.
- `match-business` returns one winner with no confidence score and no runner-up candidates. Multi-tenant brand names (Apollo, Coda, Notion, Palantir) commonly route to namesake companies in adjacent verticals; domain ≠ identity. The identity verification step (2.5) is mandatory before any 2-credit enrichment.
- 10-K-derived enrichments (`strategic-insights`, `competitive-landscape`, `challenges`) are gated on a non-null `firmo_ticker`. They are guaranteed null for private companies; calling them on private targets is wasted spend (2 credits/row). The Tier A/B split in step 3 enforces this — do not bypass.
- Sub-country geography (metro, city, sub-state) is not in the businesses endpoint. Use the prospects-side `city_region` (US autocomplete) or `prospect_region_country_code` (ISO 3166-2) as the approximation, and label the answer as "approximated from prospect distribution, not office distribution".
