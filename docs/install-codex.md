# Install Vibe Prospecting in Codex

Add the Vibe Prospecting GitHub repository as a plugin marketplace, then install the plugin from it.

## Add the GitHub marketplace

Run:

```bash
codex plugin marketplace add explorium-ai/vibeprospecting-plugin
codex plugin add vpai@vibeprospecting
```

Restart Codex if the plugin, skill, or MCP tools do not appear immediately.

## After install
follow the [Codex platform guide](../skills/vibe-prospecting/platforms/codex.md).

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Marketplace is missing or stale | Run `codex plugin marketplace upgrade vibeprospecting`, then retry `codex plugin add vpai@vibeprospecting`. |
| Plugin is installed but disabled | Set `enabled = true` under `[plugins."vpai@vibeprospecting"]` in `~/.codex/config.toml`. |
| Tools fail with auth errors | Run `npm install -g @vibeprospecting/vpai@latest`, then `vpai login`, then `vpai login --poll`. |
| Codex does not show the skill | Restart Codex after install or marketplace upgrade. |
| Need to sign out | Run `vpai logout`. |
