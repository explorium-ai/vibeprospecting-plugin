# OpenClaw: Install the Vibe Prospecting Plugin

Use this guide to install the Vibe Prospecting native plugin for OpenClaw.

## Prerequisites

- OpenClaw 2026.3.24-beta.2 or later
- Node.js 22.19.0 or later

Verify:

```bash
openclaw --version
node --version
```

## 1. Install

**From ClawHub:**

```bash
openclaw plugins install clawhub:vpai-plugin
```

**From a local bundle:**

```bash
openclaw plugins install ./vpai-openclaw.zip
```

## 2. Authenticate

Before using the plugin tools, authenticate using one of two methods.

### Option A — CLI login (recommended)

```bash
npx @vibeprospecting/vpai@latest login
```

Open the printed URL in a browser, approve access, then run:

```bash
npx @vibeprospecting/vpai@latest login --poll
```

The CLI stores credentials at `~/.config/vpai/config.json`. The Docker Compose setup bind-mounts this directory into the container, so credentials persist across restarts — no additional config needed after login.

### Option B — VP_API_KEY env var

Set `VP_API_KEY` in your shell before starting Docker Compose, or pass it directly:

```bash
VP_API_KEY=your-key-here docker compose up -d
```

## 3. Restart the gateway

After installing and setting auth, restart the OpenClaw gateway:

```bash
openclaw gateway restart
```

This is required. The plugin will not appear in tool lists until the gateway restarts.

## 4. Verify

Confirm the plugin is active:

```bash
openclaw plugins list
```

Expect `vpai` listed with status `active`.

Inspect the full plugin manifest:

```bash
openclaw plugins inspect vpai --json
```

Start a new session and ask for a Vibe Prospecting workflow, for example:

```text
Use Vibe Prospecting to find 25 US B2B SaaS companies with 50-500 employees and identify their heads of growth.
```

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `vpai` not listed after install | Re-run `openclaw plugins install`, then `openclaw gateway restart`. |
| Tools not visible in session | Restart the gateway: `openclaw gateway restart`. Tools only appear after restart. |
| `Not authenticated` error | Run `npx @vibeprospecting/vpai@latest login` then `login --poll`. Or set `VP_API_KEY`. Restart gateway after. |
| Auth / 401 on tool calls | Re-authenticate with `npx @vibeprospecting/vpai@latest login --poll` or check `VP_API_KEY`. |
| Version error during install | Verify OpenClaw >= 2026.3.24-beta.2 and Node >= 22.19.0. |
| Tools return errors | Check gateway logs: `openclaw gateway logs`. Confirm `vibeprospecting.explorium.ai` is reachable. |
| Need to sign out | Run `npx @vibeprospecting/vpai@latest logout`. |

## Plugin Structure

The plugin manifest is at the bundle root:

```text
openclaw.plugin.json
```

The plugin provides SKILL.md and reference docs. All tool execution goes through the CLI (`npx @vibeprospecting/vpai@latest`).
