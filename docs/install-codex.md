# Install Vibe Prospecting in Codex

Add the Vibe Prospecting GitHub repository as a plugin marketplace, then install the plugin from it.

## Add the GitHub marketplace

1. Open **Plugins** in Codex.
2. Click **Add plugin marketplace**.
3. In **Source**, enter:

```bash
https://github.com/explorium-ai/vibeprospecting-plugin.git
```

4. Set **Git ref** to `main`.
5. Click **Add marketplace**.
6. Search the added marketplace for **Vibe Prospecting** and click **Install**.

Restart Codex if the plugin, skill, or MCP tools do not appear immediately.

## After install
follow the [Codex platform guide](../skills/vibe-prospecting/platforms/codex.md).

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Marketplace is missing | Run `codex plugin marketplace upgrade`, then reopen `/plugins`. |
| Plugin is installed but disabled | Set `enabled = true` under `[plugins."vpai@vibeprospecting"]` in `~/.codex/config.toml`. |
| Tools fail with auth errors | Run `npm install -g @vibeprospecting/vpai@latest`, then `vpai login`, then `vpai login --poll`. |
| Codex does not show the skill | Restart Codex after install or marketplace upgrade. |
| Need to sign out | Run `vpai logout`. |