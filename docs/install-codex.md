# Codex: Install the Vibe Prospecting Plugin from GitHub

Use this guide to install the Vibe Prospecting Codex plugin from:

https://github.com/explorium-ai/vibeprospecting-plugin

The plugin name is `vpai`, and the marketplace name is usually `vibeprospecting`.

## 1. Add the GitHub Marketplace

Run this in a terminal where the Codex CLI is available:

```bash
codex plugin marketplace add explorium-ai/vibeprospecting-plugin
```

Optional: pin the install to the `main` branch:

```bash
codex plugin marketplace add explorium-ai/vibeprospecting-plugin --ref main
```

Refresh marketplaces later with:

```bash
codex plugin marketplace upgrade
```

## 2. Install and Enable the Plugin

1. Start Codex:

   ```bash
   codex
   ```

2. Open the plugin browser:

   ```text
   /plugins
   ```

3. Select the `vibeprospecting` marketplace.

4. Find `Vibe Prospecting` / `vpai`.

5. Install the plugin.

6. Make sure the plugin is enabled. Codex stores this in `~/.codex/config.toml` as:

   ```toml
   [plugins."vpai@vibeprospecting"]
   enabled = true
   ```

Restart Codex if the plugin, skill, or MCP tools do not appear immediately.

## 3. Authenticate

Before using the plugin tools, sign in with the Vibe Prospecting CLI:

```bash
npx @vibeprospecting/vpai@latest login
```

Open the printed URL in a browser, approve access, then run:

```bash
npx @vibeprospecting/vpai@latest login --poll
```

The CLI stores credentials at:

```text
~/.config/vpai/config.json
```

Verify the CLI is available:

```bash
npx @vibeprospecting/vpai@latest --help
```

## 4. Verify in Codex

Start a new Codex session and ask for a Vibe Prospecting workflow, for example:

```text
Use the Vibe Prospecting plugin to find 25 US B2B SaaS companies with 50-500 employees and identify their heads of growth.
```

You can also explicitly mention the skill if it is available:

```text
/vpai:vibe-prospecting
Find prospects at SaaS companies in New York.
```

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Marketplace is missing | Run `codex plugin marketplace upgrade`, then reopen `/plugins`. |
| Plugin is installed but disabled | Set `enabled = true` under `[plugins."vpai@vibeprospecting"]` in `~/.codex/config.toml`. |
| Tools fail with auth errors | Run `npx @vibeprospecting/vpai@latest login`, then `login --poll`. |
| Codex does not show the skill | Restart Codex after install or marketplace upgrade. |
| Need to sign out | Run `npx @vibeprospecting/vpai@latest logout`. |

## Expected Plugin Metadata

The plugin repository should expose a Codex manifest at:

```text
.codex-plugin/plugin.json
```

and a marketplace catalog at:

```text
.codex-plugin/marketplace.json
```

The MCP server configuration points Codex to:

```text
https://vibeprospecting.explorium.ai/mcp
```
