---
name: "vibe-prospecting-hubspot"
description: "Field mapping from Vibe Prospecting prospects and businesses to HubSpot Contacts and Companies, using real field names on both sides. Use this skill whenever Vibe Prospecting prospect or business data is inserted into or updated in HubSpot, including requests like \"get prospects from Vibe and insert them into HubSpot\", and whenever the user asks how Vibe Prospecting fields map to HubSpot properties."
metadata:
  version: "1.1.0"
---

# Vibe Prospecting → HubSpot field mapping

Vibe Prospecting **prospects** map to HubSpot **Contacts**. Vibe Prospecting **businesses** map to HubSpot **Companies**.

Vibe Prospecting field names are the column names in Vibe Prospecting results. HubSpot properties are shown with their label and internal name.

**When this mapping applies.** Whenever Vibe-sourced fields are written to HubSpot (insert or update), use the destinations in these tables, even if the user did not ask about mapping. This rule only decides *where* Vibe-sourced fields go. It does not authorize a write, and it does not add records or fields beyond what the user asked for.

## Property definitions are the user's to manage

- Never create or modify HubSpot property definitions or enumeration options.
- Before writing, check that each mapped destination exists on the correct object (Contacts for prospects, Companies for businesses).
- If a destination is missing, or cannot accept the raw value (for example a value that is not a valid option of an enumeration property), omit that field, report its HubSpot label and internal name, and continue with the other mapped fields.
- Do not silently substitute another destination, and do not transform, split, truncate or derive values to make them fit. The only scoped exceptions are the user-supplied list name and additional-phone extraction described below; do not apply these exceptions to other fields.

Custom destinations are marked **(custom)** and must be created by the user in HubSpot before they can receive data. Most use the `VP` label prefix and `vp_` internal-name prefix; the additional-phone defaults below use `additional_phone_number_1` through `additional_phone_number_3`. Users may change these defaults in their own skill instance.

**To change a destination:** create the property yourself in HubSpot (Settings → Properties), or pick an existing one. Then edit the row in this file: update the HubSpot label, internal name, type and the custom marker. Keep the Vibe Prospecting field name unchanged. Reinstall the updated skill.

Property names in the prose are defaults. If a destination was customized in a table, use that row's label, internal name, and type for writes and reports, including the list-name missing-field notification.

## List name for this export

Before each new export for a HubSpot push, ask the user what list name to use for its records; offer the Vibe dataset name as the default when available. If the user already supplied the name for this export, use it without asking again. Do not silently choose a name or reuse one from a different export.

Freeze the chosen name for this push and include it unchanged in the **VP List Name** (`vp_list_name`, single-line text, custom) property on every contact and company inserted or updated. It is user-supplied transfer metadata, not a Vibe result column. This is a field only: do not create a HubSpot list or add list memberships.

The list-name property is the only special missing-field notification: if it does not exist on a target object, explicitly tell the user that **VP List Name** (`vp_list_name`) is missing there and ask them to create it manually or change their skill mapping. Skip that unavailable field and continue with other available mapped fields under the usual write approval; never claim the list name was written when skipped. All other destinations retain ordinary mapping/reporting behavior.

## Show the field mapping before writing to HubSpot (required)

After the Vibe Prospecting data is exported and before any record is created or updated in HubSpot, always show the user a field-mapping report for this specific push. Build it from a live check of the target HubSpot account, not from this file alone:

1. Check every destination in the relevant table(s) below against the account. For enumeration destinations such as Lead Status, also confirm the required option exists.
2. Check the exported data: note which Vibe fields actually have values for the rows being pushed.
3. Present one table per object type being written, with these columns:

| Vibe Prospecting field | HubSpot label | Internal name | In HubSpot? | Written in this push? |
|---|---|---|---|---|

   - **In HubSpot?**: ✅ Exists (mark standard vs custom where useful) or ❌ Missing.
   - **Written in this push?**: ✅ Yes; ➖ No data (destination exists but the field is empty for these rows, with a short reason, e.g. "emails only were requested"); or ❌ Skipped (destination missing or cannot accept the value).
   - Include every mapped field from the table, not only the ones being written, so the user sees what exists and what does not.
   - Add rows for values set by this skill rather than from Vibe data (the chosen list name on contacts/companies and Lead Status on new contacts) and for associations being created (e.g. contact → existing company, with its ID).
4. Then ask for approval of the write as usual. The mapping report does not replace the HubSpot record-level confirmation; show both, or combine them in one message.

## Contacts: Vibe Prospecting prospect → HubSpot Contact

| Vibe Prospecting field | HubSpot label | HubSpot internal name | Type |
|---|---|---|---|
| `prospect_first_name` | First Name | `firstname` | Single-line text |
| `prospect_last_name` | Last Name | `lastname` | Single-line text |
| `contact_professional_email` | Email | `email` | Single-line text |
| `contact_mobile_phone` | Mobile Phone Number | `mobilephone` | Single-line text |
| `contact_phone_numbers` (additional number 1; see extraction below) | Additional Phone Number 1 **(custom)** | `additional_phone_number_1` | Single-line text |
| `contact_phone_numbers` (additional number 2; see extraction below) | Additional Phone Number 2 **(custom)** | `additional_phone_number_2` | Single-line text |
| `contact_phone_numbers` (additional number 3; see extraction below) | Additional Phone Number 3 **(custom)** | `additional_phone_number_3` | Single-line text |
| `prospect_job_title` | Job Title | `jobtitle` | Single-line text |
| `prospect_company_name` | Company Name | `company` | Single-line text |
| `prospect_company_website` | Website URL | `website` | Single-line text |
| `prospect_city` | City | `city` | Single-line text |
| `prospect_region_name` | State/Region | `state` | Single-line text |
| `prospect_country_name` | Country/Region | `country` | Single-line text |
| `prospect_linkedin` | LinkedIn URL | `hs_linkedin_url` | Single-line text |
| `prospect_id` | VP Prospect ID **(custom)** | `vp_prospect_id` | Single-line text |
| `business_id` | VP Business ID **(custom)** | `vp_business_id` | Single-line text |
| `prospect_full_name` | VP Full Name **(custom)** | `vp_full_name` | Single-line text |
| `prospect_job_department` | VP Job Department **(custom)** | `vp_job_department` | Single-line text |
| `prospect_job_seniority_level` | VP Job Seniority Level **(custom)** | `vp_job_seniority_level` | Single-line text |
| `contact_professional_email_status` | VP Email Status **(custom)** | `vp_email_status` | Single-line text |
| `prospect_experience` | VP Experience **(custom)** | `vp_experience` | Multi-line text |
| `prospect_skills` | VP Skills **(custom)** | `vp_skills` | Multi-line text |
| `prospect_interests` | VP Interests **(custom)** | `vp_interests` | Multi-line text |
| User-chosen list name (transfer metadata) | VP List Name **(custom)** | `vp_list_name` | Single-line text |

**Lead Status.** For contacts newly created from Vibe Prospecting data, set Lead Status (`hs_lead_status`) to the option labelled **New**, internal value `NEW`. Never change Lead Status on existing contacts. If `hs_lead_status` in the target account has no option labelled New, skip it and report; do not create or substitute an option.

### Additional phone extraction

Keep **`contact_mobile_phone` → `mobilephone` unchanged**. Extra numbers come from the separate **`contact_phone_numbers`** export column (the contact-enrichment field is `phone_numbers`), not from splitting `contact_mobile_phone`.

When present, the phone-array cell is an array of objects whose string **values** contain the numbers, or a JSON string encoding that array. Object keys are not a fixed `number` field and are not the source of the phone value. Parse a JSON-encoded cell once; do not split it on commas or extract numbers from arbitrary text. Walk the array in order and each object's values in their supplied order. Accept string values only; do not stringify nested objects, arrays, or numbers. A malformed JSON cell, non-array value, or non-object array item leaves the additional-phone fields unmapped for that row rather than guessing a format.

For comparison only, trim surrounding whitespace and remove spaces, parentheses, hyphens, and dots from each number; preserve a leading `+` and any explicit country code. Exclude every value with the same comparison key as `contact_mobile_phone`, skip blank values, and deduplicate the remaining values by that key in first-occurrence order. Do not infer a country code, convert `00` prefixes, or drop extensions to force equality. Write each retained value exactly as supplied, not its comparison key.

Map the first three retained values to Additional Phone Number 1, 2, and 3 respectively. The limit is three **additional** numbers, beyond the primary. Omit unused destinations without clearing existing values; ignore excess values. A missing destination keeps its assigned slot: do not shift its number into another property. Phone fields use the same pre-write mapping report and skip/no-data handling as ordinary fields—no extra prompts, missing-phone warnings, or overflow counts.

The array may not be included in a particular export. If `contact_phone_numbers` is absent or empty, handle it as ordinary unavailable source data and preserve the primary mapping. Never invent extra numbers or fetch a different data source just to fill these fields.

Synthetic example (not customer data):

```json
{
  "contact_mobile_phone": "+1 202-555-0100",
  "contact_phone_numbers": [
    {"mobile": "+1 (202) 555-0100"},
    {"direct": "+1 202-555-0101"},
    {"duplicate": "+1-202-555-0101"},
    {"office": "+1 202-555-0102"},
    {"other": "+1 202-555-0103"},
    {"extra": "+1 202-555-0104"}
  ]
}
```

Result: keep `mobilephone` as `+1 202-555-0100`; additional fields 1–3 receive `+1 202-555-0101`, `+1 202-555-0102`, and `+1 202-555-0103` unchanged. The primary, duplicate, and fourth additional number are not assigned to additional fields.

## Companies: Vibe Prospecting business → HubSpot Company

| Vibe Prospecting field | HubSpot label | HubSpot internal name | Type |
|---|---|---|---|
| `business_name` | Company name | `name` | Single-line text |
| `business_domain` | Company Domain Name | `domain` | Single-line text |
| `business_website` | Website URL | `website` | Single-line text |
| `business_city_name` | City | `city` | Single-line text |
| `business_region` | State/Region | `state` | Single-line text |
| `business_country_name` | Country/Region | `country` | Single-line text |
| `business_business_description` | Description | `description` | Multi-line text |
| `prospect_company_linkedin` | LinkedIn Company Page | `linkedin_company_page` | Single-line text |
| `business_logo` | Logo URL | `hs_logo_url` | Text (string) |
| `business_number_of_employees_range` | Employee range | `hs_employee_range` | Text (string) |
| `business_yearly_revenue_range` | Revenue range | `hs_revenue_range` | Text (string) |
| `business_id` | VP Business ID **(custom)** | `vp_business_id` | Single-line text |
| `business_naics` | VP NAICS Code **(custom)** | `vp_naics_code` | Single-line text |
| `business_naics_description` | VP NAICS Description **(custom)** | `vp_naics_description` | Single-line text |
| `business_sic_code` | VP SIC Code **(custom)** | `vp_sic_code` | Single-line text |
| `business_sic_code_description` | VP SIC Code Description **(custom)** | `vp_sic_code_description` | Single-line text |
| `business_business_intent_topics` | VP Intent Topics **(custom)** | `vp_intent_topics` | Multi-line text |
| User-chosen list name (transfer metadata) | VP List Name **(custom)** | `vp_list_name` | Single-line text |

Employee and revenue ranges go only to the range properties above, as the raw range text. Never write them to the numeric `numberofemployees` or `annualrevenue` properties.

`row_num` and `created_at` are export metadata and are not mapped.
