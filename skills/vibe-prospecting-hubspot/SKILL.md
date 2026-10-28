---
name: vibe-prospecting-hubspot
description: Field mapping from Vibe Prospecting prospects and businesses to HubSpot Contacts and Companies, using real field names on both sides. Use this skill whenever Vibe Prospecting prospect or business data is inserted into or updated in HubSpot, including requests like "get prospects from Vibe and insert them into HubSpot", and whenever the user asks how Vibe Prospecting fields map to HubSpot properties.
---

# Vibe Prospecting → HubSpot field mapping

Vibe Prospecting **prospects** map to HubSpot **Contacts**. Vibe Prospecting **businesses** map to HubSpot **Companies**.

Vibe Prospecting field names are the column names in Vibe Prospecting results. HubSpot properties are shown with their label and internal name.

**When this mapping applies.** Whenever Vibe-sourced fields are written to HubSpot (insert or update), use the destinations in these tables, even if the user did not ask about mapping. This rule only decides *where* Vibe-sourced fields go. It does not authorize a write, and it does not add records or fields beyond what the user asked for.

## Property definitions are the user's to manage

- Never create or modify HubSpot property definitions or enumeration options.
- Before writing, check that each mapped destination exists on the correct object (Contacts for prospects, Companies for businesses).
- If a destination is missing, or cannot accept the raw value (for example a value that is not a valid option of an enumeration property), omit that field, report its HubSpot label and internal name, and continue with the other mapped fields.
- Do not silently substitute another destination, and do not transform, split, truncate or derive values to make them fit.

Where no suitable existing HubSpot property was found, the field maps to a custom property with the `VP` prefix (internal name starts with `vp_`), marked **(custom)**. These must be created by the user in HubSpot before they can receive data.

**To change a destination:** create the property yourself in HubSpot (Settings → Properties), or pick an existing one. Then edit the row in this file: update the HubSpot label, internal name, type and the custom marker. Keep the Vibe Prospecting field name unchanged. Reinstall the updated skill.

## Contacts: Vibe Prospecting prospect → HubSpot Contact

| Vibe Prospecting field | HubSpot label | HubSpot internal name | Type |
|---|---|---|---|
| `prospect_first_name` | First Name | `firstname` | Single-line text |
| `prospect_last_name` | Last Name | `lastname` | Single-line text |
| `contact_professional_email` | Email | `email` | Single-line text |
| `contact_mobile_phone` | Mobile Phone Number | `mobilephone` | Single-line text |
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

**Lead Status.** For contacts newly created from Vibe Prospecting data, set Lead Status (`hs_lead_status`) to the option labelled **New**, internal value `NEW`. Never change Lead Status on existing contacts. If `hs_lead_status` in the target account has no option labelled New, skip it and report; do not create or substitute an option.

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

Employee and revenue ranges go only to the range properties above, as the raw range text. Never write them to the numeric `numberofemployees` or `annualrevenue` properties.

`row_num` and `created_at` are export metadata and are not mapped.
