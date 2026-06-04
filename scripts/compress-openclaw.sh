#!/usr/bin/env bash
# Build a marketplace-compatible OpenClaw plugin zip.
#
# The source tree keeps its multi-target layout (.claude-plugin/, .codex-plugin/,
# .openclaw-plugin/). OpenClaw expects a different shape, so this script stages a
# corrected copy into a temp dir and zips THAT — the working tree is never modified.
#
# Output zip (root layout OpenClaw can install):
#   openclaw.plugin.json   <- .openclaw-plugin/plugin.json copied verbatim (source already valid)
#   index.mjs              <- synthesized no-op runtime entry (required by the installer)
#   package.json           <- patched: openclaw.extensions + private removed
#   marketplace.json       <- Claude-format marketplace manifest (root; OpenClaw reads it)
#   skills/ ...            <- copied verbatim
#   README.md, docs/install-openclaw.md (if present)
#
# Install:  openclaw plugins install ./vpai-openclaw.zip
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${PLUGIN_DIR}/../vpai-openclaw.zip"
SRC_MANIFEST="${PLUGIN_DIR}/.openclaw-plugin/plugin.json"
SRC_MARKETPLACE="${PLUGIN_DIR}/.openclaw-plugin/marketplace.json"
SKILL_MD="${PLUGIN_DIR}/skills/vibe-prospecting/SKILL.md"

# Required by ClawHub/release validation:
#   openclaw.compat.pluginApi    -> minimum host the plugin RUNS on (loose floor, >= range)
#   openclaw.build.openclawVersion -> exact host it was BUILT against
# Keep the floor low for broad install compatibility; bump build to your tested version.
# Override: OPENCLAW_API_FLOOR=2026.5.26 OPENCLAW_VERSION=2026.5.28 bash scripts/compress-openclaw.sh
OPENCLAW_API_FLOOR="${OPENCLAW_API_FLOOR:-2026.5.26}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.5.28}"

command -v node >/dev/null || { echo "error: node is required"; exit 1; }
command -v zip  >/dev/null || { echo "error: zip is required";  exit 1; }
[ -f "$SRC_MANIFEST" ]    || { echo "error: missing $SRC_MANIFEST"; exit 1; }
[ -f "$SRC_MARKETPLACE" ] || { echo "error: missing $SRC_MARKETPLACE"; exit 1; }
[ -f "$SKILL_MD" ]        || { echo "error: missing $SKILL_MD"; exit 1; }
[ -d "${PLUGIN_DIR}/skills" ] || { echo "error: missing ${PLUGIN_DIR}/skills"; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# 1. Manifest -> root openclaw.plugin.json. Source is already valid OpenClaw
#    (skills array, configSchema, activation), so copy it verbatim — only the
#    location changes (.openclaw-plugin/ -> repo root).
cp "$SRC_MANIFEST" "${STAGE}/openclaw.plugin.json"

# 2. No-op runtime entry (skills load from the manifest; the entry is never executed).
#    id/name are derived from the manifest so they can never drift out of sync.
node -e '
  const fs = require("fs");
  const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const entry = `import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: ${JSON.stringify(m.id)},
  name: ${JSON.stringify(m.name || m.id)},
  description: "Vibe Prospecting skills bundle (CLI-backed via npx @vibeprospecting/vpai).",
  register() {
    // Skills-only plugin: no in-process tools.
  },
});
`;
  fs.writeFileSync(process.argv[2], entry);
' "${STAGE}/openclaw.plugin.json" "${STAGE}/index.mjs"

# 3. package.json -> add openclaw.{extensions,compat,build}, drop private.
#    Plugin version is taken from SKILL.md frontmatter metadata.version (single source of truth).
#    compat.pluginApi + build.openclawVersion are required by ClawHub/release validation.
OPENCLAW_API_FLOOR="$OPENCLAW_API_FLOOR" OPENCLAW_VERSION="$OPENCLAW_VERSION" node -e '
  const fs = require("fs");
  const floor = process.env.OPENCLAW_API_FLOOR;
  const ver = process.env.OPENCLAW_VERSION;
  const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  // Plugin version <- SKILL.md frontmatter metadata.version
  const md = fs.readFileSync(process.argv[3], "utf8");
  const fm = md.match(/^---\n([\s\S]*?)\n---/);
  const vm = fm && fm[1].match(/version:\s*["\x27]?([0-9][^"\x27\s]*)/);
  if (!vm) { console.error("error: could not read metadata.version from SKILL.md frontmatter"); process.exit(1); }
  delete p.private;
  delete p.scripts; // build-time only (scripts/ not shipped) — drop dead refs from the artifact
  p.version = vm[1];
  p.openclaw = Object.assign({}, p.openclaw, {
    extensions: ["./index.mjs"],
    compat: Object.assign({}, p.openclaw && p.openclaw.compat, { pluginApi: ">=" + floor }),
    build: Object.assign({}, p.openclaw && p.openclaw.build, { openclawVersion: ver }),
  });
  fs.writeFileSync(process.argv[2], JSON.stringify(p, null, 2) + "\n");
' "${PLUGIN_DIR}/package.json" "${STAGE}/package.json" "$SKILL_MD"

# 4. marketplace.json (root) — copied verbatim from the committed source
#    .openclaw-plugin/marketplace.json (Claude/Codex-style catalog entry).
cp "$SRC_MARKETPLACE" "${STAGE}/marketplace.json"

# 5. Copy skills + docs verbatim.
cp -R "${PLUGIN_DIR}/skills" "${STAGE}/skills"
# README: prefer the OpenClaw-only README so the bundle/repo doesn't ship the
# multi-host source README (which links to Claude/Codex install docs not present
# here). Fall back to README.md if the OpenClaw variant is absent.
if [ -f "${PLUGIN_DIR}/README.openclaw.md" ]; then
  cp "${PLUGIN_DIR}/README.openclaw.md" "${STAGE}/README.md"
elif [ -f "${PLUGIN_DIR}/README.md" ]; then
  cp "${PLUGIN_DIR}/README.md" "${STAGE}/README.md"
fi
if [ -f "${PLUGIN_DIR}/docs/install-openclaw.md" ]; then
  mkdir -p "${STAGE}/docs"
  cp "${PLUGIN_DIR}/docs/install-openclaw.md" "${STAGE}/docs/install-openclaw.md"
fi

# 6. Zip the staged root.
rm -f "$OUTPUT"
( cd "$STAGE" && zip -rq "$OUTPUT" . -x '*.DS_Store' )

echo "Created ${OUTPUT}"
echo "Contents:"
( cd "$STAGE" && find . -type f | sed 's|^\./|  |' | sort )
echo "Install:  openclaw plugins install ${OUTPUT}"
