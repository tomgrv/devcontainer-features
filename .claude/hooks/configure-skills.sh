#!/bin/sh

# Delegate to skillfish (knoxgraeme/skillfish)
# Installs all skills declared in ai-coding.json
#
# Runs from:
#  - devcontainer postCreate via `npm install` postinstall hook
#  - Claude Code SessionStart hook (registered in .claude/settings.json)

npx --yes knoxgraeme/skillfish@latest sync "$@"
