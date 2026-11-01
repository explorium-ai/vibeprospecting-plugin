# Install the Vibe Prospecting → HubSpot mapping skill

1. In Claude, open **Settings → Capabilities → Skills** (the section name may vary by Claude version). Enable skills if needed and choose the option to upload a skill.
2. Upload the separately distributed `vibe-prospecting-hubspot.zip`. Generated ZIPs are not stored in this repository. Upload the ZIP as-is, not the repository or plugin ZIP.
3. Enable `vibe-prospecting-hubspot` and start a new conversation. Connect Vibe Prospecting and HubSpot separately when transferring data; installing the skill does not connect either service.

The archive contains exactly one top-level folder:

```text
vibe-prospecting-hubspot/
└── SKILL.md
```

No plugin manifest, `.claude-plugin` folder, or enclosing `skills/` directory belongs in this archive.

## What the skill does

- Maps Vibe Prospecting prospects to HubSpot Contacts and businesses to Companies for both inserts and updates, including standard properties and user-managed custom properties. Employee and revenue ranges stay as text in range properties, not numeric employee/revenue fields.
- Shows a live field-mapping report before writing: which destinations exist, which values will be written, and which optional fields have no data or must be skipped. Record writes still require your approval.
- Sets Lead Status to New only on newly created contacts, when that option exists; it does not change existing contacts' status.
- By default, uses a confirmed list name for every push. The agent suggests a name based on your request and conversation, then asks you to approve or change it. The default **VP List Name** (`vp_list_name`, single-line text) must exist and accept the name on every target object type before export. You may explicitly choose another existing property or ask to skip the list-name field for a push. Otherwise a missing or incompatible destination blocks the push until resolved. The skill does not create properties or static lists.
- Keeps `contact_mobile_phone` → `mobilephone` unchanged and writes up to three additional unique numbers to **Additional Phone Number 1–3** (`additional_phone_number_1` through `additional_phone_number_3`, single-line text). It excludes the primary and formatting-equivalent duplicates, preserves source order and original values, and never clears unused phone fields.

Additional phones come from `contact_phone_numbers` in the VP export: a JSON-encoded array of phone-number strings. The skill reads the CSV cell, decodes that array, and excludes the primary wherever it appears; it does not assume the first item is primary. Unavailable or malformed source data and missing additional-phone destinations use the ordinary mapping report, without extra phone-specific prompts. A plain-text single-number cell is not treated as an array.

## Customize the mapping

Create missing destination properties manually in HubSpot, or select existing properties with equivalent meaning. Copy each property's exact internal name from HubSpot settings into the appropriate table in `skills/vibe-prospecting-hubspot/SKILL.md`; update its label, type, and custom marker as needed. Do not change the Vibe source key. Rebuild the ZIP and replace the installed skill to apply the updated mapping.

The skill does not create properties or options. Ordinary mapped fields may be skipped and reported. The list name is required by default, unless you explicitly ask to skip it; you can also choose another existing destination for a push without reinstalling. To change its default permanently, edit the destination in the skill's **List name before export** section and reinstall.
