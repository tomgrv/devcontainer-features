<!-- @format -->

# devcontainer-features MCP server

MCP server that lets an agent query this repo directly to set up **another** repo's dev environment — no need to read `README.md` or crawl `src/` by hand.

Root `.mcp.json` wires it for Claude Code auto-load on session start.

## Tools

| Tool                      | Use it to...                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------- |
| `list_features`           | Get every feature id + description (act, gitutils, githooks, ...).                    |
| `get_feature_readme`      | Read one feature's full docs before deciding to install it.                           |
| `inspect_target_repo`     | Scan a target repo's signal files (composer.json, .git, ...) and recommend features.  |
| `preview_feature_install` | Dry-run: list the files a feature would create vs. merge in a target repo, no writes. |
| `get_setup_command`       | Get the exact shell command to run in the target repo (all or one feature).           |

## Run it

```sh
node .mcp/server.js
```

## Wire it into an agent

```json
{
    "mcpServers": {
        "devcontainer-features": {
            "command": "node",
            "args": [".mcp/server.js"],
            "cwd": "/path/to/devcontainer-features"
        }
    }
}
```

Point the agent's MCP config (`.vscode/mcp.json`, Claude Desktop/Code config, etc.) at a local clone of this repo, then ask it to set up a target project: it calls `inspect_target_repo` to see what fits, `preview_feature_install` to check what a feature would touch before committing to it, and runs the command `get_setup_command` returns from inside the target repo.
