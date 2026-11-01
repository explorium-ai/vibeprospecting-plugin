# Changelog

## 1.1.0

### Added

- A user-chosen export list name, with the dataset name offered as a default, mapped to `vp_list_name` on contacts and companies. Missing list-name destinations prompt the user to create or remap the property manually.
- Up to three additional contact phones from `contact_phone_numbers`, excluding the primary mobile and formatting-equivalent duplicates while preserving original values and source order.
- User-editable `additional_phone_number_1`, `additional_phone_number_2`, and `additional_phone_number_3` destinations. Missing or unavailable phone fields use the ordinary mapping report; unused fields are not cleared.

The primary `contact_mobile_phone` → `mobilephone` mapping is unchanged. Phone-array extraction applies only when that source column is available; it does not enable a missing export column or create HubSpot properties.

## 1.0.0

First version supporting export of Vibe Prospecting data into HubSpot.

### Added

- Basic field mappings from Vibe Prospecting prospects to HubSpot Contacts and businesses to HubSpot Companies.
- A required mapping report before writing, showing which destination fields exist and which fields will be written or skipped.
- User-managed custom properties: missing destination fields are skipped and reported, never created automatically.
- Lead Status set to New for newly created contacts when that option is available.
