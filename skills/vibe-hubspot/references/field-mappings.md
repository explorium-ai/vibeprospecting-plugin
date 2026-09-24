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
| `Vibe Prospecting Last Modified` | `vibe_prospecting_last_modified` | Date-time | For an executable plan, the fixed UTC timestamp shown as `bridge-generated`; no exact timestamp is generated for a blocked dry run |

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
