#!/bin/sh

# SessionStart hook: the harness startup. Prints the durable state (progress
# log, next feature, repo rules, recent commits) and the CI status of the
# current branch on the repo's dev forge (GitHub, GitLab, Azure DevOps), so a
# session starts from files and a known-good or known-broken state instead of
# guessing. Nothing repo-controlled is executed: only fixed forge CLI queries.
# Dependencies are not installed here: the devcontainer features' own install
# (feature-install / postCreateCommand) already did that.
# Stdout is added to the session context. Silent unless the repo opted in by
# having .agents/progress.md or .agents/features.json.

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .agents/progress.md ] || [ -f .agents/features.json ] || exit 0

echo "## Harness state ($PWD)"
if [ -f .agents/progress.md ]; then
    echo "### .agents/progress.md"
    sed -n '1,40p' .agents/progress.md
fi
if [ -f .agents/features.json ] && command -v jq >/dev/null 2>&1; then
    echo "### Next unfinished feature"
    jq -r '([.features[] | select(.status != "passing" and .status != "blocked")] | sort_by(.priority) | first) as $f
        | if $f then "\($f.id) [\($f.status)] \($f.title)" else "nothing actionable (all passing or blocked)" end' \
        .agents/features.json 2>/dev/null
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
remote=$(git remote get-url origin 2>/dev/null)
case "$remote" in
*github.com*) forge=GitHub ;;
*gitlab*) forge=GitLab ;;
*dev.azure.com* | *visualstudio.com*) forge="Azure DevOps" ;;
*) forge= ;;
esac
echo "### CI status on ${forge:-unknown forge} ($branch)"
case "$forge" in
GitHub) command -v gh >/dev/null 2>&1 && gh run list --branch "$branch" --limit 3 --json workflowName,status,conclusion --jq '.[] | "\(.workflowName): \(.status) \(.conclusion)"' 2>/dev/null ;;
GitLab) command -v glab >/dev/null 2>&1 && glab ci status --branch "$branch" 2>/dev/null ;;
"Azure DevOps") command -v az >/dev/null 2>&1 && az pipelines runs list --branch "$branch" --top 3 --query "[].join(' ', [definition.name, status, result])" -o tsv 2>/dev/null ;;
esac
echo "Red CI on the forge = broken baseline: fix it before new work."

echo "### Repo rules (read before editing)"
ls CLAUDE.md AGENTS.md .agents/instructions/*.instructions.md 2>/dev/null
echo "### Recent commits"
git log --oneline -5 2>/dev/null
