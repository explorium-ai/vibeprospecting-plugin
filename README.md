# vibeprospecting-plugin

Claude plugin + skill for Explorium prospecting workflows.

The plugin vendors the CLI bundle at `skills/vibe-prospecting/scripts/vibep.js` and runs it with Node:

```bash
node skills/vibe-prospecting/scripts/vibep.js --help
```

- Prefer `--json` for skill-driven calls.
- Redirect large outputs to files and inspect only targeted fields.

Auth precedence:

1. `VP_API_KEY`
2. `~/.config/vibeprospecting/config.json`

Optional override:

- `VP_BASE_URL`
