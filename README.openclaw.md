# Vibe Prospecting Plugin for OpenClaw

**Run B2B prospecting, enrichment, research, and GTM data workflows directly inside the OpenClaw gateway.**

[![npm version](https://img.shields.io/npm/v/@vibeprospecting/vpai?style=flat-square&label=npm&color=CB3837&logo=npm&logoColor=white)](https://www.npmjs.com/package/@vibeprospecting/vpai) [![OpenClaw](https://img.shields.io/badge/OpenClaw-compatible-F97316?style=flat-square)](https://openclaw.ai) ![MCP Plugin](https://img.shields.io/badge/MCP-plugin-0052CC?style=flat-square) [![Explorium](https://img.shields.io/badge/Explorium-B2B_Data-FF6B35?style=flat-square)](https://explorium.ai)

[Getting started](#getting-started) · [Core capabilities](#core-capabilities) · [Use cases and example workflows](#use-cases-and-example-workflows) · [Tool reference](#tool-reference) · [vibeprospecting.ai ↗](https://vibeprospecting.ai)

---

## What is Vibe Prospecting Plugin?

Vibe Prospecting Plugin is a workflow layer for [Explorium's B2B data platform](https://explorium.ai), packaged as a native [OpenClaw](https://openclaw.ai) plugin. It lets users search companies, discover contacts, match raw lead lists, enrich CRM records, filter audiences, research accounts, and export structured prospecting data — all from inside an OpenClaw session.

GTM teams and AI agents can run repeatable, data-intensive workflows powered by live company and contact intelligence from Explorium's network of 150M+ companies and 800M+ professionals across 50+ data sources.

The plugin ships SKILL.md and reference docs; all tool execution runs through the `vpai` CLI (`npx @vibeprospecting/vpai@latest`).

---

## Getting started

> Requires OpenClaw 2026.3.24-beta.2+ and Node.js 22.19.0+. Full step-by-step setup, including Docker Compose, is in [`docs/install-openclaw.md`](docs/install-openclaw.md).

### Install

**From ClawHub:**

```bash
openclaw plugins install clawhub:vpai-plugin
```

**From a local bundle:**

```bash
openclaw plugins install ./vpai-openclaw.zip
```

Then restart the gateway — the plugin will not appear in tool lists until you do:

```bash
openclaw gateway restart
```

Verify it is active:

```bash
openclaw plugins list          # expect `vpai` with status `active`
```

### Authenticate

Authenticate with your Vibe Prospecting account using either method.

**Option A — CLI login (recommended):**

```bash
npx @vibeprospecting/vpai@latest login
# Open the printed URL, approve in your browser, then poll until sign-in completes:
npx @vibeprospecting/vpai@latest login --poll
```

The CLI writes credentials to `~/.config/vpai/config.json`. The Docker Compose setup bind-mounts this directory into the container, so credentials persist across restarts.

**Option B — `VP_API_KEY` env var:**

```bash
VP_API_KEY=your-key-here docker compose up -d
```

Restart the gateway after authenticating. To switch accounts or sign out, run `npx @vibeprospecting/vpai@latest logout`.

### Run your first workflow

Start a new OpenClaw session and ask:

> Find 50 B2B SaaS companies in the US with 200 to 1,000 employees. For each company, find the VP of Marketing or Head of Growth and return name, title, company, LinkedIn URL, email if available, and company domain.

### Expected output

| company_name | domain | contact_name | title | linkedin_url | email | confidence |
| --- | --- | --- | --- | --- | --- | --- |
| ExampleCo | exampleco.com | Jane Smith | VP Marketing | linkedin.com/in/janesmith | jane@exampleco.com | high |

---

## Core capabilities

| Capability | What it does | Example input | Example output |
| --- | --- | --- | --- |
| **Company search** | Finds companies by name, domain, attributes, or filters | "US banks using HubSpot" | Company list with domains and firmographics |
| **Contact discovery** | Finds people by role, seniority, function, or company | "VP Marketing at commercial banks" | Names, titles, LinkedIn URLs, emails where available |
| **Contact matching** | Resolves a raw contact (name, email, or LinkedIn URL) to a persistent Explorium person ID. That ID is stable across enrichment calls and can be used as a durable key in downstream systems. | Email, LinkedIn URL, or name + company | Persistent person ID, matched profile, confidence score |
| **Company matching** | Resolves a raw company string or domain to a persistent Explorium company ID. Useful for deduplication and as an anchor for repeated enrichment or event lookups. | Company name or domain | Persistent company ID, matched profile, confidence score |
| **Contact enrichment** | Adds missing professional fields to a contact record | LinkedIn URL or email | Email, phone, title, company, LinkedIn URL |
| **Company enrichment** | Adds firmographic fields to a company record | Domain or company name | Industry, revenue range, headcount, location, tech stack |
| **Audience filtering** | Narrows lists by ICP criteria | Headcount, revenue, industry, region, tech stack | Filtered account or contact list |
| **Event lookup** | Fetches business or prospect-level signals for an account | Company domain or ID | Recent business events, hiring signals, intent data |
| **Export** | Returns structured CSV or JSON outputs | Enriched result set | File-ready dataset for CRM import or outreach |

---

## Use cases and example workflows

Vibe Prospecting is designed for multi-step workflows — the kind you would otherwise build in Clay or n8n — but running natively inside OpenClaw. Each section below describes a use case and includes a ready-to-use prompt.

### 1 — Build a targeted prospect list

Define ICP filters, discover matching companies, find relevant contacts, enrich records, and export structured lists ready for outreach or CRM import.

**For:** GTM engineers, SDR leaders, growth operators &nbsp;|&nbsp; **Output:** CSV of qualified prospects

> Find 500 US-based cybersecurity companies with 50 to 500 employees. For each company, find the VP Sales, Head of Partnerships, or CRO. Return company name, domain, headcount, revenue range, contact name, title, LinkedIn URL, and email if available.

### 2 — Enrich CRM records

Match existing leads and accounts by email, LinkedIn URL, or name and company. Fill missing fields — title, domain, phone, revenue, headcount — and prepare clean records for CRM update.

**For:** RevOps, SalesOps, CRM admins &nbsp;|&nbsp; **Output:** Clean CSV ready for CRM import

> Take this CSV of Salesforce leads. Match each person by email, LinkedIn URL, or name and company. Add current title, company domain, LinkedIn URL, work email, phone if available, headcount, revenue, and industry. Export a clean CSV for CRM update.

### 3 — Find work emails from LinkedIn URLs

Match LinkedIn profile URLs to professional records and return verified work contact details.

**For:** SDRs, sales engineers, growth teams &nbsp;|&nbsp; **Output:** Work email, title, company, domain, confidence

> For each LinkedIn URL in this CSV, match the person to a professional profile and return work email, current company, title, company domain, and confidence level.

### 4 — Build an ABM account list

Build targeted account lists, filter by company attributes, and find two to three decision-makers per account by role and seniority.

**For:** Demand gen, field marketing, enterprise sales &nbsp;|&nbsp; **Output:** Account list with 2–3 contacts per account

> Find 300 fintech companies in North America with 100 to 2,000 employees. Filter for companies likely to have sales or marketing operations teams. Find 2 to 3 senior marketing or revenue leaders per account.

### 5 — Score inbound leads

Enrich form submissions, identify the company, evaluate ICP fit against firmographic and technographic criteria, and rank or route leads based on match score.

**For:** Marketing ops, demand gen, SDR teams &nbsp;|&nbsp; **Output:** Lead list with ICP fit score for routing

> Enrich these inbound leads, identify their companies, add headcount, revenue range, and industry, and score each lead from 1 to 5 based on ICP fit for a mid-market B2B SaaS sales motion.

### 6 — Clean and enrich a CSV

Normalize company names, deduplicate contacts, match each row to a real profile, enrich missing fields, and export a clean standardized output.

**For:** RevOps, data teams, GTM engineers &nbsp;|&nbsp; **Output:** Standardized, enriched CSV

> Normalize company names, deduplicate contacts, match each row to a person or company profile, enrich missing fields, and export a standardized CSV.

### 7 — Research account pain points

Look up company signals and summarize likely business or technical pain points per account for outbound messaging.

**For:** AEs, SDRs, ABM teams &nbsp;|&nbsp; **Output:** Account research table with outreach angles

> For these 100 target accounts, summarize likely business or technical pain points relevant to data infrastructure, GTM operations, or sales productivity. Include company name, domain, pain point summary, and suggested outreach angle.

### 8 — Run a multi-step GTM workflow

Chain company discovery, signal-based filtering, content enrichment, and contact discovery into a single workflow — the kind of pipeline you would normally build in Clay or n8n, running natively inside OpenClaw.

**For:** GTM engineers, growth teams, sales leaders &nbsp;|&nbsp; **Output:** Signal-filtered companies with qualified growth contacts

> `/vpai:vibe-prospecting`
>
> Find 500 B2B SaaS companies in the US with 200 to 1,000 employees.
> Fetch companies and filter down so that 500 companies remain after applying the event filter. Enrich each company with LinkedIn posts and keep only companies that have the keyword "event" in one of their posts.
> For the remaining companies, find the head of growth or a similar senior growth/marketing leader.
> Return the results as a CSV with these columns:
> `name, title, company, linkedin_url, professional_email, company_domain`

---

## Output examples

### Prospect output

```json
{
  "company_name": "Example Bank",
  "company_domain": "examplebank.com",
  "industry": "Commercial Banking",
  "headcount": "1,001-5,000",
  "revenue_range": "$100M-$500M",
  "contact_name": "Jane Smith",
  "title": "VP Marketing",
  "linkedin_url": "https://www.linkedin.com/in/example",
  "email": "jane.smith@examplebank.com",
  "confidence": "high"
}
```

### CRM enrichment output

```json
{
  "input_email": "sam@example.com",
  "matched_person_id": "person_123",
  "current_title": "Director of Revenue Operations",
  "current_company": "ExampleCo",
  "company_domain": "exampleco.com",
  "linkedin_url": "https://www.linkedin.com/in/example",
  "work_email": "sam@exampleco.com",
  "phone": "+1-555-000-0000",
  "match_confidence": "medium"
}
```

### Company enrichment output

```json
{
  "company_name": "ExampleCo",
  "domain": "exampleco.com",
  "industry": "B2B SaaS",
  "headcount": "201-500",
  "revenue_range": "$10M-$50M",
  "hq_country": "United States",
  "hq_city": "Austin",
  "tech_stack": ["HubSpot", "Gong", "Outreach"],
  "linkedin_url": "https://www.linkedin.com/company/exampleco"
}
```

---

## Tool reference

Full parameter documentation is in [`skills/vibe-prospecting/SKILL.md`](skills/vibe-prospecting/SKILL.md).

| Tool | Description |
| --- | --- |
| `fetch-entities` | Search for companies or contacts by structured criteria |
| `enrich-business` | Enrich a company record by domain or name |
| `enrich-prospects` | Enrich a contact record by email, LinkedIn URL, or name and company |
| `match-business` | Match a raw company record to a verified profile |
| `match-prospects` | Match a raw contact record to a verified profile |
| `fetch-entities-statistics` | Get count or aggregate statistics for a filtered entity set |
| `fetch-businesses-events` | Fetch recent business-level events for a company |
| `fetch-prospects-events` | Fetch recent events for a specific contact |
| `get-dataset` | Retrieve a previously built dataset or export |
| `export-to-csv` | Export a result set as a structured CSV |
| `autocomplete` | Autocomplete company or contact field values |
| `estimate-cost` | Estimate credit or API cost for a planned query |

---

## Security, authentication, and data handling

- Authentication is handled through your [Vibe Prospecting](https://www.vibeprospecting.ai/) account via the `vpai` CLI (`~/.config/vpai/config.json`) or the `VP_API_KEY` env var. No credentials are baked into the plugin bundle.
- All data queries are routed through Explorium's API infrastructure. Data is subject to [Explorium's data terms](https://explorium.ai) and your account permissions.
- Do not include raw API keys or credentials in prompts or exported files.
- For enterprise data handling, compliance, and DPA questions, contact [Explorium](https://explorium.ai).

---

## Troubleshooting

| Issue | Likely cause | Resolution |
| --- | --- | --- |
| `vpai` not listed after install | Gateway not restarted | Run `openclaw gateway restart`, then `openclaw plugins list` |
| Tools not visible in a session | Gateway not restarted | Tools only appear after `openclaw gateway restart` |
| `Not authenticated` / 401 on tool calls | Expired session or missing key | Run `npx @vibeprospecting/vpai@latest login --poll`, or set `VP_API_KEY`, then restart the gateway |
| Version error during install | Host or Node too old | Verify OpenClaw >= 2026.3.24-beta.2 and Node >= 22.19.0 |
| Tools return errors | Network or upstream issue | Check `openclaw gateway logs`; confirm `vibeprospecting.explorium.ai` is reachable |
| Empty results | Filters too narrow or no matches | Broaden ICP criteria or reduce required filters |
| Low email match rate | Contacts found without verified work emails | Request enrichment with a confidence threshold; email availability varies |

See [`docs/install-openclaw.md`](docs/install-openclaw.md) for the full troubleshooting table.

---

## Learn more

| Resource | Link |
| --- | --- |
| Product and site | [vibeprospecting.ai](https://vibeprospecting.ai) |
| Explorium data platform | [explorium.ai](https://explorium.ai) |
| Install guide | [docs/install-openclaw.md](docs/install-openclaw.md) |
| Skill and tool reference | [skills/vibe-prospecting/SKILL.md](skills/vibe-prospecting/SKILL.md) |
| ClawHub listing | [clawhub.ai/vibeprospecting/vpai](https://clawhub.ai/vibeprospecting/vpai) |
| Vibe Prospecting MCP (open source) | [github.com/explorium-ai/vibeprospecting-mcp](https://github.com/explorium-ai/vibeprospecting-mcp) |
| npm package | [@vibeprospecting/vpai](https://www.npmjs.com/package/@vibeprospecting/vpai) |
| Email support | <support@vibeprospecting.ai> |
| GitHub Issues | [github.com/explorium-ai/vibeprospecting-plugin-openclaw/issues](https://github.com/explorium-ai/vibeprospecting-plugin-openclaw/issues) |

---

Vibe Prospecting Plugin is built and maintained by [Explorium](https://explorium.ai). It connects [OpenClaw](https://openclaw.ai) to Explorium's B2B data platform for GTM teams, AI agents, and revenue operations workflows.
