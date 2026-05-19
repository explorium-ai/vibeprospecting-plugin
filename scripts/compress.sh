#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${PLUGIN_DIR}/../vpai-plugin.zip"

rm -f "$OUTPUT" "${PLUGIN_DIR}/../vpai.plugin"

cd "$PLUGIN_DIR"
zip -r "$OUTPUT" . \
  -x '*.DS_Store' \
  -x '.git/*' \
  -x 'node_modules/*' \
  -x 'vpai-plugin.zip' \
  -x 'vpai.plugin' \
  -x '*.zip'

echo "Created ${OUTPUT}"
