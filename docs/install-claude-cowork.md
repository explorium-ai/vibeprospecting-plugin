# Installing a Plugin from GitHub in Claude Cowork

Cowork's plugin installer works with `.plugin` files — a zip archive containing the plugin's skills, MCP config, and manifest. If a plugin is hosted on GitHub but not in the Cowork marketplace, you can package it yourself in a few steps.

## Prerequisites

- Git installed on your machine
- Node.js (only needed if the plugin includes a CLI bundle)
- A running Claude Cowork session

## Steps

### 1. Clone the repository

```bash
git clone https://github.com/explorium-ai/vibeprospecting-plugin.git
cd vibeprospecting-plugin
```

### 2. Package it as a `.plugin` file

A `.plugin` file is just a zip archive of the plugin directory. Run this from inside the cloned folder:

```bash
zip -r ../vpai.plugin . -x "*.DS_Store" -x ".git/*"
```

This creates `vpai.plugin` one level up from the cloned directory.

### 3. Install in Cowork

Open a Cowork session and ask Claude to install the file:

> "Install this plugin: `/path/to/vpai.plugin`"

Or just drag and drop the `.plugin` file into the Cowork chat window. Cowork will show a preview of the plugin's skills and a button to accept the installation.

Alternatively, you can ask Claude to fetch and package the plugin directly from the GitHub URL — Claude can clone the repo in its sandbox, zip it, and deliver the `.plugin` file to your outputs folder for you to install.

## What gets installed

The Vibe Prospecting plugin (`vpai`) includes:

- **vibe-prospecting skill** — guides Claude through building lead lists, searching companies, enriching contacts, matching CSV/JSON lists to Explorium IDs, and fetching business events
- **MCP server** — connects to `https://vibeprospecting.explorium.ai/mcp` to handle authentication; Claude will call a `get-auth-token` tool before running any data commands

## Authentication

After install, follow **[Authenticate](../README.md#authenticate)** in the plugin README. For Cowork sandbox mount paths and polling, use [`skills/vibe-prospecting/references/login.md`](../skills/vibe-prospecting/references/login.md).

## Updating

To get the latest version, re-clone the repo, re-zip, and reinstall — Cowork will replace the existing installation.

```bash
rm -rf vibeprospecting-plugin
git clone https://github.com/explorium-ai/vibeprospecting-plugin.git
cd vibeprospecting-plugin
zip -r ../vpai.plugin . -x "*.DS_Store" -x ".git/*"
```

Then install `vpai.plugin` again as in Step 3.