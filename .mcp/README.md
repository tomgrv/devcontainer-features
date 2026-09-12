<!-- @format -->

# MCP usage in this repo

This repo ships own MCP server (`src/mcp/server.js`) — let agent query this repo to set up **another** repo's dev environment, no manual `README.md`/`src/` crawl needed.

Root `.mcp.json` wire it for Claude Code auto-load on session start.

## Tools

| Tool                      | Use it to...                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------- |
| `list_features`           | Get every feature id + description (act, gitutils, githooks, ...).                    |
| `get_feature_readme`      | Read one feature's full docs before deciding to install it.                           |
| `inspect_target_repo`     | Scan a target repo's signal files (composer.json, .git, ...) and recommend features.  |
| `preview_feature_install` | Dry-run: list the files a feature would create vs. merge in a target repo, no writes. |
| `get_setup_command`       | Get the exact shell command to run in the target repo (all or one feature).           |

Full server docs (run command, manual wiring for other agents) live at `src/mcp/README.md` — canonical source, this file just point agent to `.mcp.json`.
