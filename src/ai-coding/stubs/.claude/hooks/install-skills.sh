#!/bin/sh

# Install this feature's skills straight from the source repo via
# `npx skills` (https://github.com/vercel-labs/skills), instead of shipping
# them as stub files copied into every consumer repo's .claude/skills/ or
# ~/.copilot/skills/. Skills, target agents, and companion plugins are all
# listed in .agents/registry.json (the dedicated manifest) — edit that file,
# not this script, to add/remove any of the three.
#
# Runs from two triggers:
#  - devcontainer postCreate, via configure-feature (see configure-skills.sh)
#  - Claude Code SessionStart hook, for claude.ai/code web/cloud sessions
#    (registered in .claude/settings.json)
#
# Plugins (registry.json's "plugins" list, e.g. caveman/ponytail) are not
# installed by this script: Claude Code enables them itself from
# .claude/settings.json's enabledPlugins/extraKnownMarketplaces. They're
# listed in registry.json purely so all three (skills/plugins/agents) have
# one shared reference point.

REPO="tomgrv/devcontainer-features"
REGISTRY=".agents/registry.json"

if ! command -v npx > /dev/null 2>&1; then
    echo "install-skills: npx not found, skipping skills install" >&2
    exit 0
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "install-skills: jq not found, skipping skills install" >&2
    exit 0
fi

if [ ! -f "$REGISTRY" ]; then
    echo "install-skills: $REGISTRY not found, skipping skills install" >&2
    exit 0
fi

agentFlags=""
for agent in $(jq -r '.agents[]' "$REGISTRY"); do
    agentFlags="$agentFlags -a $agent"
done

jq -r '.skills[]' "$REGISTRY" | while read -r skill; do
    npx --yes skills@latest add "$REPO/.agents/skills/$skill" $agentFlags -y \
        || echo "install-skills: failed to install '$skill'" >&2
done
