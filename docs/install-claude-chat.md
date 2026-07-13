# Connect Vibe Prospecting in Claude Chat

Vibe Prospecting runs in Claude Chat (claude.ai / Claude desktop) through its MCP connector. Claude Chat cannot run the vpai CLI, so connect it from the connector store—no GitHub clone, packaging, or command line is required.

## Connector setup

Before doing any work, check whether Vibe Prospecting MCP connector tools are in your tool list (look for `mcp__*__fetch-entities`).

If those tools are present, use them directly.

If those tools are not present, ask Claude to search the connector store for **Vibe Prospecting** or **Explorium**, then suggest the official Vibe Prospecting connector:

- If the connector is already installed but disabled for this session, select **Use** on the connector card.
- Otherwise, select **Connect** on the connector card to install and authorize it.

Re-check the tool list until `mcp__*__fetch-entities` appears. Do not start prospecting until the tools appear.

If the suggested card fails, open the **connector / integrations UI** directly, connect Vibe Prospecting there, and re-check the tool list.

## Troubleshooting

| Problem | Fix |
|---|---|
| No `mcp__*__fetch-entities` in tool list | Search the connector store for Vibe Prospecting, suggest it, then re-check tools |
| User asks to use CLI or `npx vpai` | Claude Chat cannot run the CLI; connector store is the only path |
| Connector connect fails | Open connector store, connect Vibe Prospecting again, then re-check tools |
| Auth / 401 on connector tools | Reconnect Vibe Prospecting from the connector or integrations UI |
