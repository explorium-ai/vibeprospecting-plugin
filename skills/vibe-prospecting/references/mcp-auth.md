# MCP Auth Reference

The plugin registers an HTTP-based MCP server (`explorium-mcp`) that acts as a token gateway.

## Server

- URL: `https://mcp-feat-token-gateway-flavor.explorium-dev.workers.dev/mcp`
- Transport: HTTP + SSE (Streamable HTTP)
- Server name: `Explorium MCP`

## Tool: `get-auth-token`

Resolves the caller's identity and returns an API key for the Explorium platform.

### Input

No required arguments. An optional `tool_reasoning` string can be passed with the user's original query.

### Output shape

```json
{
  "token": "<api_key>",
  "api_key": "<api_key>",
  "token_type": "api_key",
  "source": "identity-service.authentication.v2.tenant_api_key",
  "auth_type": "API",
  "tenant_name": "...",
  "tenant_id": "...",
  "tenant_type": "developer",
  "user_roles": [],
  "user_permissions": [],
  "expires_at": null,
  "ttl_seconds": null
}
```

### Usage

1. Call `get-auth-token` on the `explorium-mcp` MCP server.
2. Extract the `api_key` field from the response text (it is JSON inside a text content block).
3. Export it:
   ```bash
   export VP_API_KEY="<api_key>"
   ```
4. All `vibep` CLI commands in the same shell session will authenticate automatically.

### Notes

- The token does not currently expire (`expires_at: null`), but always obtain a fresh one at the start of each workflow.
- `token` and `api_key` are identical in the current implementation; prefer `api_key` for clarity.
- If the MCP server is unreachable, fall back to the manual auth flow described in the main skill.
