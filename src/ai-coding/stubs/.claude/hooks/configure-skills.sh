#!/bin/sh

# Delegate to Node.js sync-skills script
# Installs all skills declared in ai-coding.json via npx skills
#
# Runs from:
#  - devcontainer postCreate via `npm install` postinstall hook
#  - Claude Code SessionStart hook (registered in .claude/settings.json)

cd "$(dirname "$0")/../.." && node ./scripts/sync-skills.js
