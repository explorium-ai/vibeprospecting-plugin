# Changelog

## 1.1.0

### Added

- A required, user-confirmed export list name on every inserted or updated contact and company. The agent suggests a name from the conversation rather than using the dataset name as a default. Missing or incompatible list-name destinations block the entire push before export until manually resolved and verified.
- Up to three additional contact phones from `contact_phone_numbers`, excluding the primary mobile and formatting-equivalent duplicates while preserving original values and source order.
- User-editable `additional_phone_number_1`, `additional_phone_number_2`, and `additional_phone_number_3` destinations. Missing or unavailable phone fields use the ordinary mapping report; unused fields are not cleared.
- VP CSV phone parsing from a JSON-encoded array of strings, with the primary excluded wherever it occurs. The primary need not be present in the array; malformed or scalar cells are not guessed into an array.

The primary `contact_mobile_phone` → `mobilephone` mapping is unchanged. Phone-array extraction applies only when that source column is available; it does not enable a missing export column or create HubSpot properties.

## 1.0.0

First version supporting export of Vibe Prospecting data into HubSpot.

### Added

- Basic field mappings from Vibe Prospecting prospects to HubSpot Contacts and businesses to HubSpot Companies.
- A required mapping report before writing, showing which destination fields exist and which fields will be written or skipped.
- User-managed custom properties: missing destination fields are skipped and reported, never created automatically.
- Lead Status set to New for newly created contacts when that option is available.
