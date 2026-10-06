# Vibe → HubSpot field mappings

Use this reference after loading the complete live HubSpot names/labels/descriptions catalog. Labels and internal names vary by account. Recommendations are meaning-based, not type-validated. Every catalog property is offered from the first widget, subject only to reserved bridge destinations and one-to-one occupancy. Property types, allowed values and writability are not checked; actual failures are reported from the approved write/pilot.

## Mapping policy

Only the rows in the core tables below are predefined mappings. Confirm the destination exists in the live catalog and has equivalent meaning before recommending it; do not fetch definitions or infer value compatibility. Every other exported Vibe field stays unmapped until the user selects or creates a destination property.

Use these proposal value forms:

- `raw` — the source value is unchanged;
- `format-normalized` — only minimal syntax explicitly required by the live write tool changes;
- `bridge-generated` — metadata created by this bridge, currently limited to `vibe_prospecting_last_modified`;
- `connector-control` — a documented non-business value used only to suppress an unwanted connector default, such as `hubspot_owner_id: ""` to leave a created record unowned.

Preserve exact raw exported values universally, including numeric-looking text and JSON strings. Do not cast values, strip serialization quotes or JSON brackets, split lists, map option labels, or change representations to fit a destination. Only minimal, meaning-preserving syntax formatting explicitly documented by the live write tool itself is permitted; show `source → proposed` for every such change. Never infer destination formatting or fetch property definitions to discover it.

Never summarize, infer, translate, truncate, split a name, regroup list items, convert categories, calculate a midpoint, or derive a business value. Do not gate selection on type, allowed-value, length or format compatibility, locally or through another endpoint. Never present masked, redacted, or preview-only content as a proposed value.

## Mapping Contract presentation

The Mapping Contract is the authoritative schema for the transfer, not an informational suggestion. Present it under the exact top-level heading `REQUIRED REVIEW — HUBSPOT MAPPING CONTRACT`, before secondary explanations.

Insert and update contracts show the same exported columns. Omit only `row_num` (export bookkeeping) and columns empty, null, or missing in every row of the frozen dataset. Every remaining column gets exactly one row, including identifiers and metadata such as `created_at`; do not repeat identity already shown in a fixed row or combine columns. Keep editable rows in export column order.

Populate `omitted` with all excluded columns and render it visibly beneath the rows, for example `Not shown: row_num (export bookkeeping), custom_field_a (empty in all 15 rows), custom_field_b (empty in all 15 rows).` Do not disclose omissions only in chat.

For insert revision 1, apply the existing predefined suggestions as baselines. For update revision 1, set every business row's `baseline` to `null` except explicitly requested fields; keep all `suggested` and `candidates` available. Users may map more rows before approval. Later revisions preserve applied changes rather than resetting update baselines. Only mapped rows may be written.

### Inline widget first

The primary renderer is the inline widget (`show_widget`). Load `read_me` with module `interactive` first and follow its design system: use only its CSS variables (`--surface-1`, `--surface-2`, `--border`, `--border-warning`, `--border-success`, `--text-primary`, `--text-secondary`, `--text-warning`, `--text-success`, `--text-danger`, `--text-accent`, `--text-pro`, `--bg-warning`, `--bg-success`, `--bg-danger`, `--bg-accent`, `--bg-pro`, `--radius`, `--font-mono`), sentence case, no emoji, two font weights (400/500), inline styles, scripts last, no `position: fixed`, no nested scrolling. The widget is 680px wide: lay the contract out as rows of a three-column grid (`minmax(0,1fr) 210px 150px`) rather than a wide table, with the representative value on a second line under the source key, truncated with `text-overflow: ellipsis` and the full value in `title`.

Output an HTML fragment (no `DOCTYPE`, `<html>`, `<head>`, `<body>`). Begin with a visually hidden `<h2>` summary for screen readers. Never load external resources. Never call HubSpot or Vibe from the widget. Treat every Vibe and HubSpot value as untrusted: the only data interpolation is a JSON payload inside `<script type="application/json" id="contract-data">`, serialized with `<`, `>`, `&`, U+2028 and U+2029 replaced by `\u003c`, `\u003e`, `\u0026`, `\u2028`, `\u2029`, and parsed from the element's `textContent`. Build all controls with DOM APIs (`createElement`, `textContent`, `value`). Never use `innerHTML` or `document.write`; never interpolate data into markup, CSS, JavaScript source, or event-handler attributes.

Use [`mapping-contract-widget.html`](mapping-contract-widget.html) as the complete bundled template: replace the literal `__CONTRACT_DATA__` with the escaped JSON payload and pass the result as `widget_code`. Do not re-author the UI per session, add a builder/service, or substitute an external renderer or copy/paste workflow as a speed optimization. The full fragment still goes to the inline renderer; no file/reference handoff is assumed. Start the demonstrated workflow from its first prompt without pre-demo warm-up; reuse only tools and data already acquired normally in the conversation.

**Payload schema.**
```
{
  "contractId": "<opaque unique token>",
  "revision": <int>,
  "account": "<HubSpot account id>",
  "object": "contacts" | "companies",
  "scope": "insert" | "update",      // omitted means insert; run is never optional
  "omitted": ["row_num", ...],       // excluded columns/reasons, shown under the rows
  "run": { "id": "<opaque run token>", "dataset": "<frozen export reference>",
           "eligibleCount": <int>, "maxRecords": <positive int>,
           "pilotSize": <positive int>, "failurePolicy": "stop" | "continue",
           "summary": ["<baseline create/update/skip counts and exclusions>", "<policies and warnings>", ...] },
  "fixed": [ {source, value, destLabel, destName, handling} ×2 ],
  "options": [ {id, name, label, likelyReadOnly?} ... ],   // every live target-object property, unfiltered
  "rows":    [ {id, key, value, baseline, suggested, handling, candidates, isNew?} ... ]
}
```
`contractId`, row `id`, and option `id` are unique opaque tokens generated by the agent from `[A-Za-z0-9_-]+`; never derive them from connector data and never reuse them in the conversation. Reserve `__unmapped` and `__new`: option IDs must never equal these control tokens. `baseline` is the destination option's opaque `id`, `__new` for an unresolved custom-property decision, or `null` for unmapped. `suggested` is the option's opaque `id` for the predefined mapping (or `null`). Never put internal property names in those two fields. `handling` is the value handling frozen by the revision. `likelyReadOnly` is an optional boolean set by the writability heuristic below, not a verified permission flag. The payload carries no source or destination property types.

`scope` identifies the contract's insert/update action; missing scope defaults to `insert` for legacy payloads. `omitted` lists columns excluded by the existing rules, optionally with short reasons, and is printed as `Not shown: <entries joined>.` When empty or absent, no sentence is shown. There is no `outOfScope` field or separate hidden-field list: unrequested update columns remain visible and unmapped.

`run` is required for approval. Its token binds the widget to the stored bounded plan, not just its visible summary. `eligibleCount` is the size of the frozen, identity-resolved eligible set, including baseline no-ops that mapping edits may activate. `maxRecords` is positive and no greater than `eligibleCount`; `pilotSize` is positive and no greater than `maxRecords`. Choose actionable records deterministically in dataset order, capped by the approved maximum. `failurePolicy` defaults to `stop`; `continue` requires user choice and never permits continuation after a failed pilot. `summary` is a non-empty array of non-empty text strings shown with `textContent`.

The summary must state baseline create/update/skip counts; exclusions; fill-empty or exact previously shown overwrites; owner/association/connector controls; timestamp generation and overwrites on changed records; batch/call estimates; pilot verification and conditional continuation; and relevant warnings, including unchecked properties and non-candidate meanings. Account/object are shown in the widget header. State that final mapping edits may change actionable counts inside the eligible set, not identities, actions, maximum, or policies. Keep exact eligible stable IDs, resolved targets/actions, source values, baseline payloads, exclusions, and policies in the agent's stored run snapshot. A missing or invalid run disables approval; never fall back to mapping-only approval.

Set optional `isNew: true` when the row's baseline differs from the previous revision's baseline. Omit it in insert revision 1; in update revision 1, mark explicitly requested fields so they stand out. The widget shows `new in this revision` independently of the current changed marker.

Load the complete `options` catalog with `search_properties`, setting `objectType` and omitting `keywords`/`query`. Retrieve all names, labels and descriptions, following every returned cursor/page token. Reuse the complete snapshot across revisions and insert/update contracts for the same account/object in the conversation. Reload a lost catalog or a known catalog change and rebuild for review, not on every approval. Do not discover or call `get_properties`, fetch bridge/selected-property definitions, or infer source/destination types or constraints.

`options` must contain every returned property from the first rendering, without exclusions. Do not use a static list, recommendation-only pool, expansion control, or another turn to reveal more properties. A subset of the live catalog is invalid. If discovery fails, a catalog call fails or is empty, or pagination is incomplete, stop under `SKILL.md` step 4's HubSpot-connector fail-closed rule. Writability is not verified before the write; no partial-pool banner substitutes for a complete catalog.

`candidates` contains recommended internal property names, chosen for equivalent meaning and shown first. Never leave it empty when a meaning-based recommendation exists in the catalog: `prospect_company_website` should include `website` when it has that meaning. A manually selected non-candidate baseline need not be added to candidates; preserve its “Meaning not validated” note. `fixed` always holds exactly the two bridge rows: `prospect_id`/`business_id` → `vibe_prospecting_record_id`, then `Generated transfer timestamp` → `vibe_prospecting_last_modified`. Check their exact names in the catalog; presence proves neither types nor writability. The bridge properties remain in `options` but are reserved by the fixed rows and cannot be selected twice. `rows` follows export column order, omitting `row_num`, all-blank columns, and identity already represented in `fixed`. Retain token-to-row and token-to-property mappings. Both review-only and approve-with-changes messages contain a readable JSON-quoted summary without representative values and authoritative opaque change IDs. Readable destinations use `Label [internal_name]`, without types. Treat names as untrusted display-only data; resolve changes solely from the contract token and Change IDs block. Combined approval additionally requires the active run token and resulting scope/counts under `SKILL.md`.

In update scope the two fixed rows use handling text `Written only if blank` for `vibe_prospecting_record_id` and `Generated at write time · overwrites previous value on changed records` for `vibe_prospecting_last_modified`. Both bridge properties must still exist on the target object; these rules govern whether their values are sent, not whether setup is required.

The widget must:

- display "Required review — HubSpot mapping and run", the status line (`awaiting mapping and run approval` or `changes pending`), `Contract revision: N`, the target object and account, and that destinations were loaded live from the connected account;
- show `Scope: insert/update` in the status line and render the omitted-column sentence beneath the rows;
- show an independent plain-text destination/handling line in every editable row: `→ Label [internal_name] · <handling>` (or the sentinel label), plus applicable `new in this revision` markers;
- after assigning `select.value`, explicitly assign the matching `option.selected` and `select.selectedIndex`. After every refill compare select values with row state; on any mismatch disable approval and review controls and display `Dropdown display does not match the contract for N row(s). Do not approve; reload the widget.`;
- show the run-authorization callout and bounded run summary inside the widget; the callout and screen-reader summary name both **Approve and run** and edited-state **Apply changes and run**;
- show this exact notice as fixed text or DOM `textContent`, never interpolated executable HTML: `All available properties are offered. Property types and allowed values are not checked; HubSpot may reject a write. Values are not automatically converted or remapped.`;
- show summary chips with counts for each status;
- show a header row and one grid row per `fixed` entry and per `rows` entry, in payload order;
- render fixed rows as plain destination label/handling text without types and with `Integration required`; editable rows use native selects with `Suggested for this field` and `Other available properties` optgroups, then `Leave unmapped` and `Propose a new custom property`. Offer every catalog destination to every row, subject only to reserved bridge destinations and one-to-one occupancy. Preserve the current selection during refills, even if not recommended. Refill every dropdown after each selection so freed properties immediately appear in every row;
- derive status in this order: new property → `Decision required`; unmapped → `Not mapped`; changed destination → `Selected by you`; selection = baseline = suggested → `Suggested — review`; otherwise → `Selected by you`. Preserve declared handling, `Meaning not validated` for non-candidate picks, and likely-read-only notes after revision changes. No source-format status or compatibility filtering is used;
- give `Not mapped` rows a `--surface-1` background; give changed rows a 3px `--border-warning` left edge and a small "changed" tag;
- enforce one-to-one destinations and disable approval and review controls while duplicates exist;
- show a *Pending changes* box listing `key: old → new` when any row diverges, with a secondary **Discard changes** button;
- use green **Approve and run ↗** without pending edits and **Apply changes and run ↗** with edits, subject to approval gates; show yellow **Apply changes for review ↗** only with edits. Discarding or manually reverting all edits restores the unchanged label. Both actions use the template's canonical `sendPrompt` messages; the primary authorization text is unchanged. Approval counts count actual property selections, excluding unmapped and unresolved-property choices. Approval-with-changes submits the diff and run authorization together, without requesting revision N+1;
- show a status legend with the same chips.

`sendPrompt(text)` is the documented channel from the widget into the chat. Never use undocumented hooks.

Approval and review behaviour is defined in `SKILL.md` step 4. Review requests another revision without authorization; direct approval validates and freezes the resulting mapping at the displayed revision, then runs its verified pilot and conditional remainder.


The authoritative Markdown fallback is:

| Vibe source field | Representative value | HubSpot destination property | Value handling | Status |
|---|---|---|---|---|
| Authoritative Vibe label or exact source key | Unmasked value or `unavailable` | Property label or `Leave unmapped` | As provided / Format-normalized / Generated at write time / Not transferred | INTEGRATION REQUIRED / SUGGESTED — REVIEW / SELECTED BY YOU / DECISION REQUIRED / NOT MAPPED |
Renderer fallback order is: (1) inline widget; (2) self-contained inline/published HTML artifact with clipboard handoff; (3) five-column Markdown table. Use a fallback only when the prior renderer is unavailable or fails, never as a speed optimization. Show the complete contract and bounded run before approval. Clipboard-artifact controls use **Approve and run ↗** unchanged and **Apply changes and run ↗** with edits; yellow **Apply changes for review ↗** is optional review. They copy the exact canonical approval or review message for the user to paste, never execute connectors or treat copying as approval. Markdown offers approval of mapping and run together, or review-only changes. Both handoffs require contract/run tokens, revision, final counts and scope; direct approval may include the same authoritative diff without another rendering. Both follow the full-catalog, raw-value, type-free rules, the exact unvalidated-property notice above, insert/update baselines, fixed-row handling, visible omission sentence, and revision markers. Markdown places `Scope:` above the table and `Not shown:` below it.

The HTML artifact fallback has the same untrusted-data requirements as the widget: no external resources; escaped JSON data with `<`, `>`, `&`, U+2028 and U+2029 replaced by their Unicode escapes; parse via `textContent`; build data-bearing content with `createElement`, `textContent`, and `value`. Never interpolate connector data into markup, CSS, executable JavaScript, or event-handler attributes, and never use `innerHTML` or `document.write`.

`Vibe source field` is provenance-sensitive. Use a human-readable label only when the live Vibe tool response, schema, or column metadata explicitly supplies that label for the exact exported field. Otherwise display the exact exported key unchanged. Never infer a label by removing a prefix, replacing underscores, title-casing, or reusing the semantic labels in this reference. Preserve the exact source key internally even when an authoritative label is displayed.

For each displayed source column, scan the frozen transfer dataset in stable row order and show the first non-empty raw value, not necessarily row 1. Zero and false are non-empty. Preserve structured values as their exact exported JSON text, never a frequency summary or re-stringified representation. All-blank columns are omitted; the only missing-value placeholder is literal `unavailable`, used solely when a value exists but is inaccessible. Explain why outside the value cell. Never substitute “blank for all 15 rows”, “[cxo] for 4 rows”, masking, or descriptive statistics for a representative value.

The generated activity value is not a Vibe source field. Display its required row as `Generated transfer timestamp`; do not attribute it to Vibe.

Keep HubSpot internal property names in the frozen contract for execution, but not as primary table columns. Do not store inferred or fetched property types. Show exact internal names and values in the baseline write plan before combined approval; pending selections are visible in the widget and included in its authoritative diff.

Use only these user-facing `Value handling` labels:

- `As provided`: source value is unchanged.
- `Format-normalized`: only minimal syntax explicitly required by the live write tool changes, with the original and exact change shown.
- `Generated at write time`: integration activity metadata.
- `Connector safety control`: documented non-business value that suppresses an unwanted connector default.
- `Not transferred`: no value is written for the source field.

### Destination choices

For editable rows, show these choices in order:

1. `Suggested for this field`: meaning-based recommendations from the live catalog.
2. `Other available properties`: every remaining catalog property subject only to bridge reservation and one-to-one occupancy.
3. `Leave unmapped`.
4. `Propose a new custom property`.

There is no other-properties sentinel or chat round trip to reveal the broader pool. An explicit non-candidate pick is allowed without claiming semantic equivalence: show `Meaning not validated`, retain `Selected by you`, and show the raw value and unchecked-property warning in the write plan. Do not refuse a selection based on inferred or fetched type, allowed-value, format or length constraints. Recommendations require equivalent meaning; all selections retain exact raw values, including JSON strings, and may be rejected by HubSpot.

**Writability warning.** The connector exposes no read-only flag. Set optional `likelyReadOnly: true` when a destination description contains (case-insensitively) “set automatically”, “automatically set”, “set by HubSpot”, “managed by HubSpot”, or “calculated”; or its name is `hs_object_id`, `createdate`, `lastmodifieddate`, `hs_created_by_user_id`, or `hs_updated_by_user_id`; or starts with `hs_v2_`, `hs_analytics_`, `hs_email_`, `hs_time_`, `hs_sa_`, `hs_social_`, `notes_`, `num_`, `hs_predictive`, `hs_feedback_`, `hs_marketable_`, `engagements_`, or `ip_`. These remain selectable. Append ` · likely read-only` to option labels and selected handling cells; write-plan rows warn `may be rejected by HubSpot as read-only`. The pilot catches actual rejections and reports them per row. Never retry a rejected write under the same approval.

**Write rejection.** A read-only, type, allowed-value/enum, format or length rejection is an actual write failure. Record the affected property and rows; any pilot rejection stops continuation regardless of the run's failure policy. A failed call may have partial or uncertain effects: verify successful rows and reconcile uncertain outcomes under `SKILL.md` before deciding whether untouched remainder may continue. Never automatically convert, remap, retry or correct under the old approval.

**Controlled assignments.** Boundary 3 remains an agent rule, not a pool filter. If the user maps onto owner, lifecycle-stage, lead-status, or marketing-contact-status properties, name the assignment plainly in the write plan and ask the user to confirm it is intended before execution approval; never silently drop the mapping.

A widget selection becomes authoritative only after its review or approval message reaches the agent and passes validation. Review-only changes produce a new revision; approval-with-changes freezes the resulting mapping and authorizes the bounded run without another rendering. For clipboard and Markdown fallbacks, show the complete contract and run before handoff and use the same validation rules.

### Mapping statuses

Use these exact statuses and show their meanings directly below every Mapping Contract:

- `INTEGRATION REQUIRED`: mandatory integration mapping; the user cannot redirect or remove it.
- `SUGGESTED — REVIEW`: meaning-based suggestion; review before running.
- `SELECTED BY YOU`: destination explicitly selected by the user.
- `DECISION REQUIRED`: the user must select a destination or leave the field unmapped.
- `NOT MAPPED`: field will not be transferred.

`Propose a new custom property` does not have its own status. Keep that row `DECISION REQUIRED` until the property is separately approved and created, rediscovered in the live HubSpot catalog, and selected in a revised contract.

### Approval boundary

Label each complete rendering `Contract revision: N` and `Status: AWAITING MAPPING AND RUN APPROVAL`. Summarize integration-required, suggested, user-selected, decision-required and not-mapped counts.

Combined approval freezes the final source key, destination name and declared value handling, plus the bounded run identified by its token. Pending edits are validated atomically and frozen without another mapping revision or approval turn. Preserve token/revision/replay, scope/count, baseline/diff, catalog-membership, bridge-reservation, duplicate-destination, unresolved-property and readable-summary checks. Never fetch definitions or validate type/allowed-value/length/format compatibility on review or approval. Known catalog removals or account/scope changes invalidate approval; an unobserved property failure is reported from the actual write. Approval authorizes pilot writes and conditional continuation, not additional Vibe credit spend, property creation, unshown associations/overwrites, corrective writes, or retries. Subsequent mapping or execution-scope changes require a revised proposal and approval.

## Company mappings

| Vibe meaning | HubSpot meaning | Default | Rules |
|---|---|---|---|
| Company/business name | Company name | Predefined | Raw value. Do not replace a legal name with a brand name or vice versa. |
| Primary company domain | Company domain name | Predefined | Preserve the raw write value unless the live write tool explicitly requires minimal syntax formatting; show any such change. Use normalized exact domain for fallback lookup. |
| Website URL | Company website URL | Predefined | Raw URL. Do not synthesize a URL from a domain. |
| Company phone | Company phone number | Predefined | Raw value; preserve the country code. |
| Business description | Description | Predefined | Raw value only. Never summarize or truncate; HubSpot may reject the write. |
| Street address | Street address | Predefined | Raw value. |
| City | City | Predefined | Raw value. |
| State/region | State/Region | Predefined | Raw value. Do not translate or map option labels. |
| Country | Country/Region | Predefined | Raw value. |
| Postal code | Postal code | Predefined | Preserve raw text and leading zeroes. |
| LinkedIn company URL | LinkedIn company page | Predefined | Exact URL when a catalog property has that meaning; writability is not verified. |
| Employee range | Employee range or equivalent meaning | Predefined only for equivalent meaning | Keep the exact range text. Do not calculate an employee count or automatically recommend a count field for a range. |
| Revenue range | Revenue range or equivalent meaning | Predefined only for equivalent meaning | Keep the exact range text. Do not calculate a midpoint or automatically recommend an amount field for a range. |
| Industry/category/code | User-selected property | Manual | Preserve raw values and warn if destination meaning is not validated. Do not convert between classification systems or map option labels. |
| `business_id` | Vibe Prospecting Record ID | Required | Store the raw ID on inserts; on updates write `vibe_prospecting_record_id` only when blank. Never overwrite an existing ID. |
| Parent company or subsidiary identity | Parent-company association | Manual | This is an identity decision and separate association write. Do not merge or associate automatically. |

## Contact mappings

| Vibe meaning | HubSpot meaning | Default | Rules |
|---|---|---|---|
| First name | First name | Predefined | Raw value. |
| Last name | Last name | Predefined | Raw value. |
| Full name only | User-selected full-name property | Manual | Do not split it into first and last name. |
| Vibe-enriched email | Email | Predefined | Raw email. Use every returned email for fallback lookup. If separate returned emails need one primary destination, ask which should be primary; do not discard one silently or split a raw JSON string. |
| Work phone | Phone number | Predefined | Raw value; preserve the country code. |
| Mobile phone | Mobile phone number | Predefined | Use only when Vibe identifies it as mobile. |
| Current job title | Job title | Predefined | Raw value. |
| LinkedIn profile URL | LinkedIn profile URL | Predefined | Exact URL when a catalog property has that meaning; writability is not verified. |
| Current company name | Contact company name | Predefined | Write the raw Vibe company name to the contact's Company name property, typically internal name `company`, when present with equivalent meaning in the live catalog. This mapping does not create or change a company association; its type and writability are not checked. |
| Current company identity | Associated company | Manual | Resolve the HubSpot company separately. Association requires its own planned action, `tool_guidance`, and explicit approval. |
| Company domain | Company lookup evidence | Manual | Use for company resolution; do not write it into an unrelated contact property. |
| Contact city/state/country | Contact location fields | Predefined | Only when Vibe identifies them as the contact's location. |
| `prospect_id` | Vibe Prospecting Record ID | Required | Store the raw ID on inserts; on updates write `vibe_prospecting_record_id` only when blank. Never overwrite an existing ID. |

## Other exported Vibe fields

No automatic mapping is defined for fields outside the core tables. Show each non-omitted Vibe column, its first non-empty raw value (or `unavailable` only if inaccessible), meaning-based recommendations, and the full catalog subject only to bridge reservation and one-to-one occupancy. Leave it unmapped until the user explicitly selects a destination or approves creation of a dedicated property.

Names, descriptions and equivalent meaning support recommendations, not inferred value compatibility. Explicit non-candidate selections follow the `Meaning not validated` rule above; they never permit re-stringifying structured values or semantic transformation. All selections carry the unchecked-property notice, with no type/format/length/allowed-value preflight.

## Conflict and overwrite policy

1. **HubSpot blank:** propose filling it.
2. **Same value after declared format normalization:** no business-field write is needed.
3. **Different non-empty value:** preserve HubSpot by default; show the conflict.
4. **User requests overwrite:** show `current → proposed`, source, value form, and warning before approval.
5. **Source blank:** never erase the HubSpot value.
6. **Source ambiguous:** do not write it; include the warning and let the user choose.

## Mandatory identity and activity properties

For separately approved setup only, create missing properties on each HubSpot object type used by the bridge using this specification. These creation types are not fetched or validated during normal insert/update transfers:

| Label | Internal name | Type | Written value |
|---|---|---|---|
| `Vibe Prospecting Record ID` | `vibe_prospecting_record_id` | Single-line text | Company `business_id` or contact `prospect_id` |
| `Vibe Prospecting Last Modified` | `vibe_prospecting_last_modified` | Date-time | Fixed UTC timestamp generated immediately before each approved write call under the approved generation rule and recorded in the transfer ledger; no timestamp is generated for a blocked dry run |

Both bridge properties must exist before inserts or updates. Inserts write both values. Updates fill `vibe_prospecting_record_id` only when blank and preserve every existing non-empty ID. Generate and overwrite `vibe_prospecting_last_modified` only for records receiving at least one approved business-property change; label the overwrite in the contract and show `current → proposed` in the write plan when a previous timestamp exists. Skip no-op records entirely, without touching either bridge value. The ID is durable bridge identity; the timestamp records this bridge's HubSpot activity, not Vibe source-modification time or HubSpot's general last-modified time.

Property creation is itself a HubSpot write. If either exact name is missing from the complete `search_properties` catalog, stop data writes and ask the client to create it, or propose an exact property-creation write and obtain approval. Rediscover created names through the catalog afterward. Presence does not verify types or writability. If the client declines, inserts and updates through this bridge cannot proceed.

Resolve an existing company by exact `vibe_prospecting_record_id`, then normalized exact domain. Resolve an existing contact by exact `vibe_prospecting_record_id`, then each exact email, then exact LinkedIn profile URL. Do not fall back to fuzzy names. If an update target is not found, stop and suggest a separately approved insert.

## Connector-default controls

On create, inspect the live write schema for owner defaults. If it documents that omitting `hubspot_owner_id` assigns the current user and `hubspot_owner_id: ""` leaves the record unowned, include the empty string and show `Owner: unowned` as a `connector-control` in the exact proposal. If the schema does not document a safe suppression value, do not guess. Never send a non-empty owner ID unless the user explicitly requests and approves that assignment after owner resolution.

## Suggested proposal labels

Use human-readable labels in approval tables while retaining internal property names privately for tool calls:

- Raw source value
- Format-normalized value
- Bridge-generated metadata
- Connector-default suppression control
- User-selected destination
- Existing HubSpot value retained
- Unmapped — no predefined equivalent
