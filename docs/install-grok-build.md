# Install Vibe Prospecting in Grok Build

Vibe Prospecting uses the `vpai` CLI for company and contact discovery, enrichment, research, and CSV exports in Grok Build. You need Grok Build with shell access, Node.js/npm, and a Vibe Prospecting account.

## Marketplace status

The xAI marketplace submission is pending review: [xai-org/plugin-marketplace#609](https://github.com/xai-org/plugin-marketplace/pull/609). Submission does not mean the plugin is already listed. Authenticated end-to-end use in Grok Build has not yet been verified.

## Install after the listing is accepted

Once `vpai` appears in the built-in marketplace, run:

```bash
grok plugin marketplace list
grok plugin install vpai --trust
```

Alternatively, open `/marketplace` inside Grok Build, find `vpai` (Vibe Prospecting), and press `i` to install. These follow [xAI's marketplace instructions](https://x.ai/news/grok-plugin-marketplace).

The plugin uses the existing `.claude-plugin/plugin.json` manifest, which the [xAI marketplace accepts](https://github.com/xai-org/plugin-marketplace/blob/main/CONTRIBUTING.md). No separate Grok manifest is required.

## After install

Follow the [CLI platform guide](../skills/vibe-prospecting/platforms/other.md) for CLI installation, browser sign-in, schema discovery, and workflow execution. Grok Build explicitly routes to this guide.

The guide installs `@vibeprospecting/vpai@latest` at the start of each workflow. The marketplace pins the plugin repository to a Git commit; that pin does not pin the separately installed CLI package.

Try a first prompt:

```text
Use Vibe Prospecting to find US B2B SaaS companies with 200 to 1,000 employees and identify their heads of marketing. Show the complete five-company sample before running a larger export.
```

The default workflow previews five entities through the full requested chain before asking to run at scale. To bypass that preview for a single request, explicitly ask to skip the sample.

## Troubleshooting

- **`vpai` is not in the marketplace:** check the submission status above; the marketplace installation command applies only after the listing is accepted and available in your catalog.
- **Authentication fails:** follow `vpai login`, `vpai login --poll`, and `vpai whoami` in the CLI guide. Do not paste credentials into prompts.
- **Wrong platform guide is loaded:** identify the host as Grok Build and load `skills/vibe-prospecting/platforms/other.md`. A generic shell environment block does not identify Claude Code.
