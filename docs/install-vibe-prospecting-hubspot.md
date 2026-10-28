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

## Customize the mapping

Create missing destination properties manually in HubSpot, or select existing properties with equivalent meaning. Copy each property's exact internal name from HubSpot settings into the appropriate table in `skills/vibe-prospecting-hubspot/SKILL.md`; update its label, type, and custom marker as needed. Do not change the Vibe source key. Rebuild the ZIP and replace the installed skill to apply the updated mapping.

The skill skips and reports missing destination fields; it does not create properties or options. Lead Status New is used only if the connected account exposes that option.
