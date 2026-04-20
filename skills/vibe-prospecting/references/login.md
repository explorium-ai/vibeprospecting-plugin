# vpai CLI — Login & Setup Guide

This file documents the exact steps required to authenticate `npx @vibeprospecting/vpai@latest` in a Cowork sandbox session. Follow this before running any vpai tool.

---

## Step 1 — Use the CLI via npx

Do not install the CLI globally. Run the published package directly with `npx @vibeprospecting/vpai@latest` for every command.

Use the full `npx @vibeprospecting/vpai@latest ...` command for every invocation in this session.

---

## Step 2 — Mount the Local Config Directory

The API key is stored on the **user's local machine** at `~/.config/vpai/config.json`. The sandbox cannot reach it directly.

`~/.config/vpai/` is reserved for `config.json` only. Do not save exports, logs, temporary files, or any other artifacts there.

Try mounting that directory first using the `request_cowork_directory` MCP tool:

```
mcp__cowork__request_cowork_directory  path: ~/.config/vpai
```

If that mount succeeds, the directory is available inside the sandbox at `/sessions/<session-id>/mnt/vpai/`.

If mounting `~/.config/vpai` fails, fall back to mounting the parent directory instead:

```
mcp__cowork__request_cowork_directory  path: ~/.config
```

That mount is available at `/sessions/<session-id>/mnt/.config/`. Create the `vpai/` subdirectory inside it before continuing:

```bash
mkdir -p /sessions/<session-id>/mnt/.config/vpai
```

Then check whether a key already exists:

```bash
cat /sessions/<session-id>/mnt/vpai/config.json
# or, if you mounted ~/.config instead:
cat /sessions/<session-id>/mnt/.config/vpai/config.json
```

---

## Step 3 — Authenticate (choose the path that applies)

Treat `~/.config/vpai/config.json` on the local host machine as the durable auth source. Never treat sandbox `~/.config/vpai/config.json` as durable auth state.

Do not create or save any file under `~/.config/vpai/` other than `config.json`.

### ✅ Path A — API key exists in config.json

The file contains something like `{ "api_key": "abc123..." }`. Configure the CLI with it:

```bash
API_KEY=$(python3 -c "import json; print(json.load(open('/sessions/<session-id>/mnt/vpai/config.json'))['api_key'])")
npx @vibeprospecting/vpai@latest config --api-key "$API_KEY"
```

If you mounted `~/.config` instead of `~/.config/vpai`, read from `/sessions/<session-id>/mnt/.config/vpai/config.json`.

This is the default path for later sessions. Reuse the saved key instead of doing interactive login again.

→ Skip to **Step 4**.

---

### ❌ Path B — API key is missing or config.json does not exist

The file is absent, empty, or does not contain an `api_key` field. You need to log in via browser.

**3B-1. Start the login flow** — this prints a URL:

```bash
npx @vibeprospecting/vpai@latest login
# Output: https://explorium.auth0.com/activate?user_code=XXXX-XXXX
#         Then: npx @vibeprospecting/vpai@latest login --poll
```

**3B-2. Open the URL in your browser** and approve the request.

**3B-3. Complete login and retrieve the API key:**

```bash
npx @vibeprospecting/vpai@latest login --poll-show
# Output includes the tenant API key — copy it
```

If the CLI says you are already signed in, continue to `npx @vibeprospecting/vpai@latest login --poll-show` and then save the printed key.

**3B-4. ⚠️ Write the key to the mounted local config path first** — this is critical so future sessions skip the browser step:

```bash
# If ~/.config/vpai was mounted directly:
mkdir -p /sessions/<session-id>/mnt/vpai
echo '{"api_key":"<paste-key-here>"}' > /sessions/<session-id>/mnt/vpai/config.json

# If ~/.config was mounted instead:
mkdir -p /sessions/<session-id>/mnt/.config/vpai
echo '{"api_key":"<paste-key-here>"}' > /sessions/<session-id>/mnt/.config/vpai/config.json
```

Do not write the key only to the sandbox's own `~/.config` path.

**3B-5. Save the same key on the local machine if you are completing the flow outside the mounted path:**

```bash
# On your LOCAL machine (not in the sandbox), run:
mkdir -p ~/.config/vpai
echo '{"api_key":"<paste-key-here>"}' > ~/.config/vpai/config.json
```

**3B-6. Rehydrate the CLI from the saved key:**

```bash
API_KEY=$(python3 -c "import json; print(json.load(open('/sessions/<session-id>/mnt/vpai/config.json'))['api_key'])")
npx @vibeprospecting/vpai@latest config --api-key "$API_KEY"
```

If you mounted `~/.config` instead of `~/.config/vpai`, read from `/sessions/<session-id>/mnt/.config/vpai/config.json`.

---

## Step 4 — Verify

```bash
npx @vibeprospecting/vpai@latest --help
```

If the help output lists all tools (`match-business`, `fetch-entities`, etc.), the CLI is ready.

---

## Quick Reference

### Path A (key already saved locally)

```bash
# Mount config dir via request_cowork_directory (path: ~/.config/vpai)
# If that fails, mount ~/.config and create /sessions/<session-id>/mnt/.config/vpai
# Then configure:
API_KEY=$(python3 -c "import json; print(json.load(open('/sessions/<session-id>/mnt/vpai/config.json'))['api_key'])")
# or, if ~/.config was mounted instead:
# API_KEY=$(python3 -c "import json; print(json.load(open('/sessions/<session-id>/mnt/.config/vpai/config.json'))['api_key'])")
npx @vibeprospecting/vpai@latest config --api-key "$API_KEY"

# Verify
npx @vibeprospecting/vpai@latest --help
```

### Path B (no key saved — first time or after logout)

```bash
# Login via browser
npx @vibeprospecting/vpai@latest login
# → open printed URL in browser, approve
npx @vibeprospecting/vpai@latest login --poll-show
# → copy the printed API key

# Write the key to the mounted local path first
echo '{"api_key":"<key>"}' > /sessions/<session-id>/mnt/vpai/config.json
# or, if ~/.config was mounted instead:
echo '{"api_key":"<key>"}' > /sessions/<session-id>/mnt/.config/vpai/config.json

# Configure CLI from the saved key
API_KEY=$(python3 -c "import json; print(json.load(open('/sessions/<session-id>/mnt/vpai/config.json'))['api_key'])")
# or, if ~/.config was mounted instead:
# API_KEY=$(python3 -c "import json; print(json.load(open('/sessions/<session-id>/mnt/.config/vpai/config.json'))['api_key'])")
npx @vibeprospecting/vpai@latest config --api-key "$API_KEY"

# Verify
npx @vibeprospecting/vpai@latest --help
```

### Sign out or switch account

```bash
npx @vibeprospecting/vpai@latest logout
```

Then repeat Path B.

### No browser fallback

If you already have a tenant API key, configure it directly:

```bash
npx @vibeprospecting/vpai@latest config --api-key "<tenant-api-key>"
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `npx @vibeprospecting/vpai@latest` fails to run | Verify `npx` can reach npm and retry |
| `Not authenticated` error | Re-run Step 3 — sandbox config does not persist between sessions |
| Can't find config.json | Try `request_cowork_directory` with `path: ~/.config/vpai`; if that fails, mount `~/.config` and create `/sessions/<session-id>/mnt/.config/vpai` |
| Login URL flow (fallback) | `npx @vibeprospecting/vpai@latest login` → open URL in browser → `npx @vibeprospecting/vpai@latest login --poll-show` → write the printed key to the mounted local config path |
| Need to switch tenants/accounts | Run `npx @vibeprospecting/vpai@latest logout`, then do Path B again |

---

## Notes

- Use `request_cowork_directory` only for the config mount step. Run all vpai operations via `npx @vibeprospecting/vpai@latest`.
- The sandbox `~/.config/vpai/config.json` is **not durable** — it is recreated each session. Always read the key from the mounted local machine path.
- The local machine's `~/.config/vpai/config.json` is the single source of truth for the API key.
- No file other than `config.json` should ever be saved under `~/.config/vpai/`.
