# Changelog

## 1.0.0

First version supporting export of Vibe Prospecting data into HubSpot.

### Added

- Basic field mappings from Vibe Prospecting prospects to HubSpot Contacts and businesses to HubSpot Companies.
- A required mapping report before writing, showing which destination fields exist and which fields will be written or skipped.
- User-managed custom properties: missing destination fields are skipped and reported, never created automatically.
- Lead Status set to New for newly created contacts when that option is available.
