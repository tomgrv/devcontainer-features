#!/bin/sh

# SessionStart hook: the harness startup. Prints the durable state (progress
# log, next feature, repo rules, recent commits) and runs the baseline
# verification named in .agents/features.json ("baseline"), so every session
# starts from files and a known-good or known-broken state instead of guessing.
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

    baseline=$(jq -r '.baseline // empty' .agents/features.json 2>/dev/null)
    if [ -n "$baseline" ]; then
        echo "### Baseline verification: $baseline"
        if command -v timeout >/dev/null 2>&1; then
            out=$(timeout 600 sh -c "$baseline" 2>&1)
        else
            out=$(sh -c "$baseline" 2>&1)
        fi
        rc=$?
        if [ "$rc" -eq 0 ]; then
            echo "PASS"
        else
            echo "FAIL (exit $rc) - fix the baseline before new work"
            echo "$out" | tail -20
        fi
    fi
fi
echo "### Repo rules (read before editing)"
ls CLAUDE.md AGENTS.md .agents/instructions/*.instructions.md 2>/dev/null
echo "### Recent commits"
git log --oneline -5 2>/dev/null
