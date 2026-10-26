---
name: "vibe-prospecting-hubspot"
description: Field mapping from Vibe Prospecting data (prospects and businesses) to HubSpot Contacts and Companies, using the real field names on both sides. Use this skill whenever the user asks how Vibe Prospecting fields map to HubSpot, which HubSpot property a Vibe Prospecting field goes to, which custom properties are needed, or wants to send Vibe Prospecting results into HubSpot, even if they don't say the word "mapping".
---

# Vibe Prospecting → HubSpot field mapping

Vibe Prospecting **prospects** map to HubSpot **Contacts**. Vibe Prospecting **businesses** map to HubSpot **Companies**.

Vibe Prospecting field names are the column names in Vibe Prospecting results. HubSpot properties are shown with their label and internal name.

Where a Vibe Prospecting field has no HubSpot property of the same type, it maps to a custom HubSpot property with the `VP` prefix (internal name starts with `vp_`). Custom properties are marked **(custom)**. Create a custom property in HubSpot before writing to it.

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

* Set hubspot field 'Lead Status' to New for newely added contacts

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
| `business_id` | VP Business ID **(custom)** | `vp_business_id` | Single-line text |
| `business_logo` | VP Logo URL **(custom)** | `vp_logo_url` | Single-line text |
| `business_naics` | VP NAICS Code **(custom)** | `vp_naics_code` | Single-line text |
| `business_naics_description` | VP NAICS Description **(custom)** | `vp_naics_description` | Single-line text |
| `business_sic_code` | VP SIC Code **(custom)** | `vp_sic_code` | Single-line text |
| `business_sic_code_description` | VP SIC Code Description **(custom)** | `vp_sic_code_description` | Single-line text |
| `business_number_of_employees_range` | VP Number of Employees Range **(custom)** | `vp_number_of_employees_range` | Single-line text |
| `business_yearly_revenue_range` | VP Yearly Revenue Range **(custom)** | `vp_yearly_revenue_range` | Single-line text |
| `business_business_intent_topics` | VP Intent Topics **(custom)** | `vp_intent_topics` | Multi-line text |

`row_num` and `created_at` are export metadata and are not mapped.
