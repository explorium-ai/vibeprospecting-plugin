# Install Vibe Prospecting on other platforms

For hosts that are not Claude Code, Claude Chat, Cowork, Codex, or OpenClaw—terminals, scripts, CI, or other agent environments—clone the plugin repository and load it locally.

## 1. Clone the repository

```bash
git clone https://github.com/explorium-ai/vibeprospecting-plugin.git
cd vibeprospecting-plugin
```

## 2. Load the plugin or skills

**If your host has a plugin system:** load this repository as a plugin using that host’s normal local-plugin install path (point it at the cloned folder).

**If your host has no plugin system:** load all skills under `skills/` into the agent, then use the `vpai` CLI for every tool call.

## After install

You **must** follow the [other platforms guide](../skills/vibe-prospecting/platforms/other.md) for auth, workflow, and usage.
