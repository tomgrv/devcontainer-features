#!/bin/sh

# Install this feature's Claude Code skills straight from the source repo via
# `npx skills` (https://github.com/vercel-labs/skills), instead of shipping
# them as stub files copied into every consumer repo's .claude/skills/.
#
# Runs from two triggers:
#  - devcontainer postCreate, via configure-feature (see configure-skills.sh)
#  - Claude Code SessionStart hook, for claude.ai/code web/cloud sessions
#    (registered in .claude/settings.json)

REPO="tomgrv/devcontainer-features"

SKILLS="
caveman
caveman-commit
caveman-compress
caveman-help
caveman-review
feature-ai-coding
pm/metrics-digest
pm/prd-draft
pm/release-notes
pm/research-synthesis
pm/roadmap-brief
"

if ! command -v npx >/dev/null 2>&1; then
    echo "install-skills: npx not found, skipping Claude Code skills install" >&2
    exit 0
fi

for skill in $SKILLS; do
    npx --yes skills@latest add "$REPO/.agents/skills/$skill" -a claude-code -y ||
        echo "install-skills: failed to install '$skill'" >&2
done
