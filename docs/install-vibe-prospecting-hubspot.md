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
- Requires a confirmed list name for every push. The agent suggests a name based on your request and conversation, then asks you to approve or change it. **VP List Name** (`vp_list_name`, single-line text) must exist and accept the name on every target object type—Contacts, Companies, or both—before export. Every inserted or updated record receives that name. A missing or incompatible list-name property blocks the push until you fix it manually; the skill does not create properties or static lists.
- Keeps `contact_mobile_phone` → `mobilephone` unchanged and writes up to three additional unique numbers to **Additional Phone Number 1–3** (`additional_phone_number_1` through `additional_phone_number_3`, single-line text). It excludes the primary and formatting-equivalent duplicates, preserves source order and original values, and never clears unused phone fields.

Additional phones require `contact_phone_numbers` in the VP export. The [Contact information API documentation](https://developers.explorium.ai/v2/prospects/enrichments/contact_information_enrich) defines the API field `phone_numbers` as an array of objects with phone-number string values; it does not guarantee that VP exposes it. Unavailable source data or missing additional-phone destinations use the ordinary mapping report, without extra phone-specific prompts.

## Customize the mapping

Create missing destination properties manually in HubSpot, or select existing properties with equivalent meaning. Copy each property's exact internal name from HubSpot settings into the appropriate table in `skills/vibe-prospecting-hubspot/SKILL.md`; update its label, type, and custom marker as needed. Do not change the Vibe source key. Rebuild the ZIP and replace the installed skill to apply the updated mapping.

The skill does not create properties or options. Ordinary mapped fields may be skipped and reported, but the list name is required. To use a different list-name property, edit its label, internal name, and type in the skill's **Required list name before export** section and reinstall. Changing the destination does not make the list name optional.
