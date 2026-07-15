#!/usr/bin/env bash
# Generate OpenClaw skills from Claude-plugin command files.
#
# OpenClaw plugins have no `commands` concept — the manifest supports skills
# only, and skills surface as /slash_commands in chat (dashes -> underscores).
# This script converts each <commands-dir>/<name>.md (Claude Code command
# format: frontmatter `description`, `$ARGUMENTS` placeholder) into
# <skills-out-dir>/<name-dashed>/SKILL.md so the same command content ships on
# OpenClaw without manual duplication. Skill version comes from the main
# SKILL.md frontmatter (single source of truth, same as compress-openclaw.sh).
#
# Usage: commands-to-openclaw-skills.sh <commands-dir> <skills-out-dir> <version-source-SKILL.md>
set -euo pipefail

COMMANDS_DIR="$1"
OUT_DIR="$2"
VERSION_SRC="$3"

# No commands dir -> nothing to generate (not an error).
[ -d "$COMMANDS_DIR" ] || exit 0

command -v node >/dev/null || { echo "error: node is required"; exit 1; }
[ -f "$VERSION_SRC" ] || { echo "error: missing $VERSION_SRC"; exit 1; }

node -e '
  const fs = require("fs"), path = require("path");
  const [commandsDir, outDir, versionSrc] = process.argv.slice(1);

  const md = fs.readFileSync(versionSrc, "utf8");
  const fm = md.match(/^---\n([\s\S]*?)\n---/);
  const vm = fm && fm[1].match(/version:\s*["\x27]?([0-9][^"\x27\s]*)/);
  if (!vm) { console.error("error: could not read metadata.version from " + versionSrc); process.exit(1); }
  const version = vm[1];

  for (const file of fs.readdirSync(commandsDir).filter((f) => f.endsWith(".md"))) {
    const raw = fs.readFileSync(path.join(commandsDir, file), "utf8");
    const m = raw.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
    const descMatch = m && m[1].match(/^description:\s*(.+)$/m);
    const desc = descMatch ? descMatch[1].trim() : "";
    const body = (m ? m[2] : raw).replace(/\$ARGUMENTS/g, "the rest of the user\x27s message after the slash command");
    const name = path.basename(file, ".md").replace(/_/g, "-");
    const skillDir = path.join(outDir, name);
    fs.mkdirSync(skillDir, { recursive: true });
    const frontmatter = [
      "---",
      `name: "${name}"`,
      `description: "${desc.replace(/"/g, "\\\"")}"`,
      "metadata:",
      `  version: "${version}"`,
      "---",
      "",
    ].join("\n");
    fs.writeFileSync(path.join(skillDir, "SKILL.md"), frontmatter + body);
    console.error(`[commands->skills] ${file} -> ${name}/SKILL.md`);
  }
' "$COMMANDS_DIR" "$OUT_DIR" "$VERSION_SRC"
