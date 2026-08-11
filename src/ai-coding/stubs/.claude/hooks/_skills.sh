#!/bin/sh

# npx-skills wrapper for this feature. Single source of truth for turning
# ai-coding.json (repo root — the merged manifest of skills/agents/plugins
# from this feature and any other feature that dependsOn it and ships its
# own stubs/ai-coding.json fragment) into live state:
#   - skills installed into each declared agent's folder, via
#     `npx skills` (https://github.com/vercel-labs/skills)
#   - plugins declared in .claude/settings.json's enabledPlugins /
#     extraKnownMarketplaces (the "associated settings file" for Claude
#     Code plugins)
#
# Usage: _skills.sh [sync]   (sync is the default when no command given)
#
# Runs from two triggers:
#  - devcontainer postCreate, via configure-feature (see configure-skills.sh)
#  - Claude Code SessionStart hook, for claude.ai/code web/cloud sessions
#    (registered in .claude/settings.json), so cloud sessions stay in sync
#    with ai-coding.json too.

REPO="tomgrv/devcontainer-features"
REGISTRY="ai-coding.json"
SETTINGS=".claude/settings.json"
command="${1:-sync}"

if [ ! -f "$REGISTRY" ]; then
    echo "_skills.sh: $REGISTRY not found, skipping" >&2
    exit 0
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "_skills.sh: jq not found, skipping" >&2
    exit 0
fi

sync_skills() {
    if ! command -v npx > /dev/null 2>&1; then
        echo "_skills.sh: npx not found, skipping skills sync" >&2
        return 0
    fi

    agentFlags=""
    for agent in $(jq -r '.agents[]' "$REGISTRY"); do
        agentFlags="$agentFlags -a $agent"
    done

    jq -r '.skills[]' "$REGISTRY" | while read -r skill; do
        npx --yes skills@latest add "$REPO/.agents/skills/$skill" $agentFlags -y \
            || echo "_skills.sh: failed to install skill '$skill'" >&2
    done
}

sync_plugins() {
    [ -f "$SETTINGS" ] || return 0

    plugins=$(jq -c '.plugins // []' "$REGISTRY")
    [ "$plugins" = "[]" ] && return 0

    merged=$(jq --argjson plugins "$plugins" '
        reduce $plugins[] as $p (.;
            .enabledPlugins[$p.marketplace + "@" + $p.name] = true
            | .extraKnownMarketplaces[$p.marketplace] = {"source": {"source": "git", "url": $p.url}}
        )' "$SETTINGS") || {
        echo "_skills.sh: failed to sync plugins into $SETTINGS" >&2
        return 1
    }

    printf '%s\n' "$merged" >"$SETTINGS"
}

case "$command" in
sync)
    sync_skills
    sync_plugins
    ;;
*)
    echo "_skills.sh: unknown command '$command' (expected: sync)" >&2
    exit 1
    ;;
esac
