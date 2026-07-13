---
description: Skip sample-first mode for this request — fetch/enrich at full scale without a 5-entity preview
---

# Skip sample (this request only)

**Hosts:** Claude Code, Codex, OpenClaw, and other CLI hosts only (`claude-code.md`, `codex.md`, `openclaw.md`, `other.md`). Not Claude Chat or Cowork — those have no Sample Gate.

The user's query is:

$ARGUMENTS

**First:** load the normal Vibe Prospecting skill (`vibe-prospecting` / `/vpai:vibe-prospecting`), detect the host, and read the matching **CLI** platform guide. Follow that skill for install, auth, schema discovery, autocomplete, chaining, and export rules.

**Then, for this user turn only**, override Sample Gate:

1. Do **not** run the 5-entity sample preview.
2. Do **not** wait for approval before full scale.
3. Run the **complete** prospecting workflow at the user's requested scale immediately.
4. This does **not** persist — later messages without an explicit skip return to sample-first mode.
5. After full scale, copy **`csv_path`** to the working directory with a proper name based on the user's question.

Treat `$ARGUMENTS` as the normal prospecting request. If `$ARGUMENTS` is empty, ask what they want to fetch or enrich at full scale.
