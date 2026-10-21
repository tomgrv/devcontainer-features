#!/bin/sh

# SessionStart hook: prints the harness state (progress log, next feature,
# recent commits) so every session starts from the durable files instead of
# guessing. Stdout is added to the session context. Silent unless the repo
# opted in by having claude-progress.md or feature_list.json at its root.

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f claude-progress.md ] || [ -f feature_list.json ] || exit 0

echo "## Harness state ($PWD)"
if [ -f claude-progress.md ]; then
    echo "### claude-progress.md"
    sed -n '1,40p' claude-progress.md
fi
if [ -f feature_list.json ] && command -v jq >/dev/null 2>&1; then
    echo "### Next unfinished feature"
    jq -r '([.features[] | select(.status != "passing")] | sort_by(.priority) | first) as $f
        | if $f then "\($f.id) [\($f.status)] \($f.title)" else "all features passing" end' \
        feature_list.json 2>/dev/null
fi
echo "### Recent commits"
git log --oneline -5 2>/dev/null
echo "Run ./init.sh and the baseline verification before starting new work."
