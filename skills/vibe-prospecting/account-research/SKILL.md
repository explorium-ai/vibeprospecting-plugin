---
name: account-research
description: Produce a high-signal intelligence brief on a target company using Explorium firmographics, technographics, funding, hiring and challenge signals, business events, recent website and LinkedIn moves, plus a peer cohort. Identify the account by Explorium business_id (preferred) or by company name or domain (which triggers a match step). Always lead with a TL;DR framed by the user's stated research purpose (QBR prep, competitive analysis, cold outbound, renewal risk, expansion).
---

# Account Research
Build a purpose-driven intelligence brief on a single target company, anchored on the user's stated reason for pulling the brief.

## Input
- Account identifier (required): a business ID, a company name, or a domain.
- Research context (strongly recommended): one sentence on why this brief is being pulled and what decision it supports (QBR prep, competitive eval vs Acme, cold outbound to finance leaders). This shapes enrichment selection, event triage, and the TL;DR framing.

Example phrasings: "Build a brief on stripe.com for cold outbound to finance leaders.", "Account brief for business_id abc123, QBR next week, watch renewal signals.", "Profile Snowflake, competitive analysis vs Databricks."

## Workflow

1. Anchor on purpose. Restate the research context in one sentence as the brief purpose. If missing, ask once; if the user declines, default to general account intelligence and state that assumption. Derive 2 to 4 priority themes (e.g. for QBR renewal risk: workforce changes, exec moves, competing vendors, expansion signals). Themes drive enrichment selection.

2. Resolve the company. If a business ID was supplied, use it. Otherwise match the business by name or domain. Sanity-check the resolved firmographics: if a major-brand input returns 1-50 employees and Corporate-Managing-Offices category, the match likely routed to a shell entity. Retry with the alternate domain or the name string before proceeding. If no confident match emerges, surface the ambiguity to the user before continuing.

3. Enrich in chunked passes, treating each enrichment as context retrieval. Always pull firmographics, hierarchies, funding and acquisitions, challenges, strategic insights, workforce trends, LinkedIn posts, and website changes. For competitive briefs, add competitive landscape, technographics, webstack. For QBR / renewal, add company ratings. For investor / M&A angles, add financial metrics. For keyword-driven outbound, add website keywords tied to your offering or themes.

4. Fetch business events scoped to the last 90 days: hiring spikes, leadership changes, funding rounds, product launches, layoffs, office moves, tech adoption. Verify each event headline actually mentions the target before counting it: industry-wide articles can cross-attribute.

5. Build a peer cohort (directional). There is no native similar-companies tool, so approximate: combine firmographics, technographics, and a tight industry sub-category rather than a broad industry label (a broad label routes mega-tech defaults like Google or Amazon into a small-tech peer query). Size the audience to confirm cohort volume, then sample the top 10 to 20 peers. Flag the section as directional, not an exact match list.

6. Synthesize against the brief purpose. Keep events and signals that map to the purpose, priority themes, or non-obvious flags. Mark past-date enrichments (funding close, exec start, last website change) as needing verification. Suppress sections that lack volume: skip funding for public mega-caps, skip the peer cohort with fewer than 5 confident matches, flatten challenges or insights to bullets when only 1-3 items. Cross-reference signals (new CTO plus a webstack change plus engineering hiring = a clear timing signal).

7. Write the exec summary last. Re-read the body, then write the TL;DR. The Situation line must explicitly answer "why this brief, now" against the stated purpose.

## Output Format

### TL;DR: [Company Name]
Brief purpose (restated, or "general account intelligence" if defaulted). Then: **Situation** (2 to 4 sentences answering "why this brief, now" against the stated purpose), **Top 3 facts** (most consequential data points), **Highest-leverage actions** (1 to 3 concrete actions tied to specific signals).

### Company Snapshot
A compact field table: Domain, Industry, Headcount bucket, Revenue bucket, HQ Country / Region, Public / Private, Founded, business_id.

### Firmographics & Hierarchy
Firmographics plus parent / subsidiary structure. Note recent restructuring.

### Funding & Capital Structure
Total raised, most recent round date and amount, acquisitions. For public mega-caps, reference the ticker instead.

### Workforce & Hiring Signals
Net headcount change, departmental growth, hiring spikes or contractions. Flag exec moves surfaced via LinkedIn posts or events.

### Tech Stack & Website Activity
Tools in use, recent additions or removals, keyword shifts. Highlight items mapping to the user's offering or competitors.

### Challenges & Strategic Insights
Stated pain points, public priorities, expansion plans. Tie back to brief purpose.

### Recent Events (last 90 days)
Grouped list (Funding / Leadership / Hiring / Product / Risk) when 4+ items span categories, otherwise flat. Each item: event type, date, one-line summary. Call out timing opportunities (new CTO equals vendor evaluation likely).

### Peer Cohort (directional)
One-line caveat that the set is approximated from shared industry, size, and country, not exact similarity. Then a top-10 table: Company, Domain, Size, Revenue, Country.

### Key Takeaways & Next Steps
3 to 5 bullets connecting dots across sources, framed by the stated purpose. Then concrete next actions tied to specific signals, people, or moments. Omit any line without a concrete target.

## Limitations
- Strategic-insights and challenges signals come from public filings: null for private companies and 12-18 months stale for public ones. Use events, funding, workforce, and LinkedIn posts for current state.
- No native similar-companies tool; the peer cohort is approximated from shared industry, size, and country and flagged as directional.
- No native intent-topic scoring; intent-style signals come from events, website changes, website keywords, and LinkedIn posts rather than a single ranked feed.
- No AI-generated outbound copy; this skill produces the brief, downstream skills handle messages.
- Bucket-only headcount and revenue. Finer company-type distinctions (subsidiary, JV, PE-backed) must be read from hierarchies and funding rather than filtered.
- Business match returns no confidence score; infer ambiguity from the candidate set and confirm with the user.
