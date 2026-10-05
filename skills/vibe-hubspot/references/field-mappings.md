# Vibe → HubSpot field mappings

Use this reference only after reading the live HubSpot property schema. Labels and internal names vary by account. A mapping is valid only when the destination property exists, is writable, accepts the source type/value, and has the same meaning.

## Mapping policy

Only the rows in the core tables below are predefined mappings. Validate each one against the live HubSpot schema before proposing it. Every other exported Vibe field stays unmapped until the user selects or creates a destination property.

Use these proposal value forms:

- `raw` — the source value is unchanged;
- `format-normalized` — only syntax required by the destination changes;
- `bridge-generated` — metadata created by this bridge, currently limited to `vibe_prospecting_last_modified`;
- `connector-control` — a documented non-business value used only to suppress an unwanted connector default, such as `hubspot_owner_id: ""` to leave a created record unowned.

Permitted normalization is mechanical and meaning-preserving: trim surrounding whitespace when required, remove serialization-only quotes or brackets, convert a date to the destination's required representation, or canonicalize a domain for HubSpot's domain field. Show `source → proposed` for every normalization.

Never summarize, infer, translate, truncate, split a name, regroup list items, convert categories, calculate a midpoint, or derive a business value. If the destination cannot accept the raw value with only mechanical formatting, leave it unmapped. Never present masked, redacted, or preview-only content as a proposed value.

## Mapping Contract presentation

The Mapping Contract is the authoritative schema for the transfer, not an informational suggestion. Present it under the exact top-level heading `REQUIRED REVIEW — HUBSPOT MAPPING CONTRACT`, before secondary explanations.

The contract covers every exported column present in the current transfer dataset, not every field Vibe could theoretically return. Use exactly one row per exported column, including blank, specialized, identifier, and metadata columns. Never combine `row_num` and `created_at`.

### Inline HTML artifact first

The primary renderer is an **inline HTML artifact**. On Claude, explicitly create an `inline HTML artifact`; HTML inside a Markdown code fence does not satisfy this requirement. Attempt the artifact before any Markdown fallback.

Build one self-contained HTML document with inline CSS and JavaScript. It must not load external scripts, fonts, images, analytics, or network resources, and it must never call HubSpot or Vibe directly. Treat every dynamic Vibe and HubSpot value as untrusted, including source keys, labels, representative values, property labels, internal names, types, and enum options. The only permitted data interpolation is a JSON payload inside `<script type="application/json" id="contract-data">`: serialize it as JSON, replace `<`, `>`, `&`, U+2028, and U+2029 with their Unicode escape sequences, then parse the element's `textContent`. Construct controls with DOM APIs such as `createElement`, `textContent`, and `value`. Never interpolate live data anywhere else, including HTML markup, executable JavaScript source, CSS, or event-handler attributes; never use `innerHTML` or `document.write`.

The artifact must:

- display `REQUIRED REVIEW — HUBSPOT MAPPING CONTRACT`, `Status: AWAITING MAPPING APPROVAL`, and `Contract revision: N` prominently;
- state that destination properties were loaded from the user's connected HubSpot account for this contract revision;
- render exactly these five visible columns:

| Vibe source field | Representative value | HubSpot destination property | Value handling | Status |
|---|---|---|---|---|
| Authoritative Vibe label or exact source key | Unmasked value or `unavailable` | Interactive destination selector or fixed text | User-facing handling label | Colored status chip |

- use a native `<select>` or accessible searchable combobox only for editable destinations;
- render the fixed record-ID and transfer-timestamp destinations as plain text, never disabled dropdowns;
- show `INTEGRATION REQUIRED` in the Status column for both fixed rows;
- preselect predefined mappings as `SUGGESTED — REVIEW`;
- populate options only from the live, writable properties retrieved from the user's connected HubSpot account with `search_properties` and, when needed, `get_properties`; never use a static destination list;
- use the HubSpot internal property name as the selection identity while showing the label and type;
- enforce one-to-one mapping: a destination internal name selected or fixed in one row is unavailable in every other row, while sentinel choices such as `Leave unmapped` may repeat;
- immediately release a destination when its row changes selection and disable approval if duplicate destination identities are ever present;
- update the row status and summary counts immediately when the selection changes;
- give every `NOT MAPPED` row a gray background in addition to its gray status chip;
- keep `row_num`, `created_at`, unsupported fields, and every other exported column visible;
- show a **Status legend** below the table;
- render every legend enum with the same status-chip CSS class and exact colors used in table rows;
- provide one primary action control and no separate copy button;
- remain keyboard-usable and readable on narrow screens.

Render the fixed rows only after the live schema confirms `vibe_prospecting_record_id` as writable single-line text and `vibe_prospecting_last_modified` as writable date-time. If either property is absent or has the wrong type, block Mapping Contract approval, complete the separately approved property-creation workflow, rediscover the properties, and build a new revision.

The fixed rows are:

- Vibe `business_id` or `prospect_id` → `Vibe Prospecting Record ID`, status `INTEGRATION REQUIRED`;
- `Generated transfer timestamp` → `Vibe Prospecting Last Modified`, status `INTEGRATION REQUIRED`, value handling `Generated at write time`.

Do not expose internal implementation terminology in the table.

Claude Chat does not expose a documented artifact API for submitting form state into the parent conversation. Do not use undocumented `postMessage` events or imply that a button click updated the agent.

When no row is `DECISION REQUIRED`, label the primary control **Approve mapping**. On click:

1. Validate that no destination is duplicated, both fixed rows have `INTEGRATION REQUIRED`, and every selected destination belongs to the live schema snapshot.
2. Serialize the complete contract revision, including exact source keys and destination labels, internal names, types, value handling, and statuses.
3. Prepare one canonical chat message that states approval and contains that complete contract.
4. Use the Clipboard API to place the message on the clipboard and show `Approval prepared — paste and send it in chat to continue`. If clipboard access fails, display the same message in a read-only text area for manual transfer.

When any row is `DECISION REQUIRED`, use that same primary control but label it **Continue in chat**. Prepare a clearly non-approving message containing the complete contract, every unresolved row, and every custom-property proposal. This message lets the agent continue the separately approved property-creation or decision workflow; it must not state approval or freeze the contract.

Do not render a separate clipboard control. Clicking either artifact button state alone must not authorize or trigger HubSpot or Vibe calls. A pasted **Approve mapping** message is the actual mapping-approval boundary. After the user sends it, re-fetch the live HubSpot schema and compare it with the artifact snapshot before accepting approval. If any selected property changed, became read-only, disappeared, or either fixed property is invalid, reject the stale approval and render a new revision. Otherwise validate the message, echo the Mapping Contract as approved, and do not ask for a redundant second confirmation.

Do not preemptively choose Markdown because artifact support is uncertain. Use the five-column Markdown table only if the host actually cannot create or render an inline HTML artifact, artifact rendering fails, or the selected contract cannot be recovered.

`Vibe source field` is provenance-sensitive. Use a human-readable label only when the live Vibe tool response, schema, or column metadata explicitly supplies that label for the exact exported field. Otherwise display the exact exported key unchanged. Never infer a label by removing a prefix, replacing underscores, title-casing, or reusing the semantic labels in this reference. Preserve the exact source key internally even when an authoritative label is displayed.

The generated activity value is not a Vibe source field. Display its required row as `Generated transfer timestamp`; do not attribute it to Vibe.

Keep HubSpot internal property names and destination types in the frozen contract data for execution, but do not add them as primary table columns. Show the exact internal names and values later in the write proposal and tool-call details.

Use only these user-facing `Value handling` labels:

- `As provided`: source value is unchanged.
- `Format-normalized`: only syntax required by the destination changes.
- `Generated at write time`: integration activity metadata.
- `Connector safety control`: documented non-business value that suppresses an unwanted connector default.
- `Not transferred`: no value is written for the source field.

### Destination choices

For editable rows, order choices as follows:

1. Predefined exact mapping when it exists.
2. Other writable properties with equivalent meaning and compatible type.
3. `Leave unmapped`.
4. `Show other writable properties`.
5. `Propose a new custom property`.

Do not flood the initial selector with every text property. Exclude read-only, calculated, hidden, and structurally incompatible properties. `Show other writable properties` may reveal the broader list, but label semantically incompatible choices and require explicit manual selection.

A selection is not accepted until it is returned from the artifact and echoed in the complete Mapping Contract. If the artifact path fails under the conditions above, use the Markdown table fallback; never skip the contract.

### Mapping statuses

Use these exact statuses and show their meanings directly below every Mapping Contract:

- `INTEGRATION REQUIRED`: mandatory integration mapping; the user cannot redirect or remove it.
- `SUGGESTED — REVIEW`: predefined compatible mapping; the user must still review it.
- `SELECTED BY YOU`: destination explicitly selected by the user.
- `DECISION REQUIRED`: the user must select a destination or leave the field unmapped.
- `NOT MAPPED`: field will not be transferred.
- `INCOMPATIBLE`: no safe compatible destination exists.

`Propose a new custom property` does not have its own status. Keep that row `DECISION REQUIRED` until the property is separately approved and created, rediscovered in the live HubSpot schema, and selected in a revised contract.

### Approval boundary

Label each complete rendering `Contract revision: N` and `Status: AWAITING MAPPING APPROVAL`. Summarize integration-required, suggested, user-selected, decision-required, not-mapped, and incompatible counts.

Mapping approval freezes the exact source key, destination internal name, type, and value handling for that revision. It does not approve Vibe credit spend, property creation, associations, overwrites, or record writes. Any mapping change requires a complete revised contract and new mapping approval.

## Company mappings

| Vibe meaning | HubSpot meaning | Default | Rules |
|---|---|---|---|
| Company/business name | Company name | Predefined | Raw value. Do not replace a legal name with a brand name or vice versa. |
| Primary company domain | Company domain name | Predefined | Canonicalize only to the syntax required by HubSpot's domain property and show the change. Use the normalized exact value for fallback lookup. |
| Website URL | Company website URL | Predefined | Raw URL when compatible with the live property. Do not synthesize a URL from a domain. |
| Company phone | Company phone number | Predefined | Raw value unless the live property requires mechanical phone formatting; preserve the country code. |
| Business description | Description | Predefined | Raw value only. If it exceeds the live property limit, leave it unmapped rather than summarize or truncate it. |
| Street address | Street address | Predefined | Raw value. |
| City | City | Predefined | Raw value. |
| State/region | State/Region | Predefined | Raw value only when the live field accepts it. Do not translate or convert it to an enum option. |
| Country | Country/Region | Predefined | Raw value only when the live field accepts it. |
| Postal code | Postal code | Predefined | Preserve leading zeroes and use a text-compatible destination. |
| LinkedIn company URL | LinkedIn company page | Predefined | Exact URL when a writable property with that meaning exists. |
| Employee range | Employee range or equivalent text property | Predefined only for equivalent meaning | Keep the exact range text. Do not calculate an employee count or write it to a numeric count field. |
| Revenue range | Revenue range or equivalent text property | Predefined only for equivalent meaning | Keep the exact range text. Do not calculate a midpoint or write it to a numeric revenue field. |
| Industry/category/code | User-selected equivalent property | Manual | Write only to a property whose allowed value has exactly the same meaning. Do not convert between classification systems. |
| `business_id` | Vibe Prospecting Record ID | Required | Store the raw ID in `vibe_prospecting_record_id` on every insert/update. |
| Parent company or subsidiary identity | Parent-company association | Manual | This is an identity decision and separate association write. Do not merge or associate automatically. |

## Contact mappings

| Vibe meaning | HubSpot meaning | Default | Rules |
|---|---|---|---|
| First name | First name | Predefined | Raw value. |
| Last name | Last name | Predefined | Raw value. |
| Full name only | User-selected full-name property | Manual | Do not split it into first and last name. |
| Vibe-enriched email | Email | Predefined | Raw email. Use every returned email for fallback lookup. If Vibe returns multiple emails but HubSpot exposes one compatible destination, ask which value should be primary; do not discard one silently. |
| Work phone | Phone number | Predefined | Raw value unless the live property requires mechanical formatting; preserve the country code. |
| Mobile phone | Mobile phone number | Predefined | Use only when Vibe identifies it as mobile. |
| Current job title | Job title | Predefined | Raw value. |
| LinkedIn profile URL | LinkedIn profile URL | Predefined | Exact URL when a writable property with that meaning exists. |
| Current company name | Contact company name | Predefined | Write the raw Vibe company name to the contact's writable Company name property, typically internal name `company`, after live schema validation. This is a contact text field; it does not create or change a company association. |
| Current company identity | Associated company | Manual | Resolve the HubSpot company separately. Association requires its own planned action, `tool_guidance`, and explicit approval. |
| Company domain | Company lookup evidence | Manual | Use for company resolution; do not write it into an unrelated contact property. |
| Contact city/state/country | Contact location fields | Predefined | Only when Vibe identifies them as the contact's location. |
| `prospect_id` | Vibe Prospecting Record ID | Required | Store the raw ID in `vibe_prospecting_record_id` on every insert/update. |

## Other exported Vibe fields

No automatic mapping is defined for fields outside the core tables. Show the Vibe column, a representative value, and compatible live HubSpot candidates. Leave it unmapped until the user chooses an equivalent destination or approves creation of a dedicated property.

A destination accepting text is not enough to establish a valid mapping. Do not pack structured values into one text field unless the user explicitly selects that representation and the write plan shows the exact raw value.

## Conflict and overwrite policy

1. **HubSpot blank:** propose filling it.
2. **Same value after declared format normalization:** no business-field write is needed.
3. **Different non-empty value:** preserve HubSpot by default; show the conflict.
4. **User requests overwrite:** show `current → proposed`, source, value form, and warning before approval.
5. **Source blank:** never erase the HubSpot value.
6. **Source ambiguous:** do not write it; include the warning and let the user choose.

## Mandatory identity and activity properties

Create these properties on every HubSpot object type used by the bridge:

| Label | Internal name | Type | Written value |
|---|---|---|---|
| `Vibe Prospecting Record ID` | `vibe_prospecting_record_id` | Single-line text | Company `business_id` or contact `prospect_id` |
| `Vibe Prospecting Last Modified` | `vibe_prospecting_last_modified` | Date-time | Fixed UTC timestamp generated immediately before each approved write call under the approved generation rule and recorded in the transfer ledger; no timestamp is generated for a blocked dry run |

Both properties are required for every data insert/update. `vibe_prospecting_record_id` is the durable bridge identity. `vibe_prospecting_last_modified` records the time of this bridge's HubSpot activity and is overwritten by each later approved update. It is not a Vibe source-modification timestamp and is not HubSpot's built-in all-purpose last-modified property.

Property creation is itself a HubSpot write. If either property is missing, stop data writes and ask the client to create it, or propose an exact property-creation write and obtain approval. If the client declines, inserts and updates through this bridge cannot proceed.

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
