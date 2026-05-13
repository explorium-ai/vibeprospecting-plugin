# Installing the Vibe Prospecting Plugin for Claude Code

This guide explains how to install the [Vibe Prospecting plugin](https://github.com/explorium-ai/vibeprospecting-plugin) from GitHub into Claude Code by editing `~/.claude/settings.json`.

## Steps

### 1. Open `~/.claude/settings.json`

If the file doesn't exist yet, create it with `{}` as the initial content.

### 2. Add the GitHub marketplace

Add an entry under `extraKnownMarketplaces` that points Claude Code to the plugin repo:

```json
{
  "extraKnownMarketplaces": {
    "vibeprospecting": {
      "source": {
        "source": "github",
        "repo": "explorium-ai/vibeprospecting-plugin"
      }
    }
  }
}
```

### 3. Enable the plugin

Add the plugin to `enabledPlugins` using the `plugin-name@marketplace-id` format:

```json
{
  "enabledPlugins": {
    "vpai@vibeprospecting": true
  }
}
```

### 4. Full example

A complete `~/.claude/settings.json` with only this plugin looks like:

```json
{
  "extraKnownMarketplaces": {
    "vibeprospecting": {
      "source": {
        "source": "github",
        "repo": "explorium-ai/vibeprospecting-plugin"
      }
    }
  },
  "enabledPlugins": {
    "vpai@vibeprospecting": true
  }
}
```

If you have other plugins or settings already in the file, merge these keys in — don't replace the whole file.

### 5. Restart Claude Code

The plugin is fetched and installed on startup. After restarting, the `vibe-prospecting` skill and its tools will be available.

## Next: authenticate

After install, follow **[Authenticate](../README.md#authenticate)** in the plugin README (login, verify, Cowork sandbox notes, logout).
