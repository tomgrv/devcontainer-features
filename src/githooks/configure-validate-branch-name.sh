#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

# Branch/prefix scheme is the git-flow config set by the gitutils feature's
# configure-gitflow.sh (git config gitflow.branch.* / gitflow.prefix.*).
# Fall back to git-flow's own defaults if that feature isn't installed.
master_branch=$(git config gitflow.branch.master || echo "main")
develop_branch=$(git config gitflow.branch.develop || echo "develop")
feature_prefix=$(git config gitflow.prefix.feature || echo "feature/")
bugfix_prefix=$(git config gitflow.prefix.bugfix || echo "bugfix/")
release_prefix=$(git config gitflow.prefix.release || echo "release/")
hotfix_prefix=$(git config gitflow.prefix.hotfix || echo "hotfix/")
support_prefix=$(git config gitflow.prefix.support || echo "support/")

# AI coding agents push to prefixes outside the git-flow scheme; keep those
# allowed too, overridable via GITHOOKS_EXTRA_BRANCH_PREFIXES (comma-separated).
extra_prefixes="${GITHOOKS_EXTRA_BRANCH_PREFIXES:-copilot,claude}"

prefixes=$(printf '%s,%s,%s,%s,%s,%s' \
    "$feature_prefix" "$bugfix_prefix" "$release_prefix" "$hotfix_prefix" "$support_prefix" "$extra_prefixes" |
    tr ',' '\n' | sed 's#/*$##' | grep -v '^$' | paste -sd '|' -)

pattern="^(${master_branch}|${develop_branch}){1}\$|^(${prefixes})/.+\$"

jq -n \
    --arg masterBranch "$master_branch" \
    --arg developBranch "$develop_branch" \
    --arg prefixes "$prefixes" \
    --arg pattern "$pattern" \
    '{"validate-branch-name": {
        "errorMsg": ("Please use a branch name that follows the pattern: (\($masterBranch)|\($developBranch)) or (\($prefixes))/<description>.\nUse git push --no-verify to bypass this check if necessary."),
        "pattern": $pattern
    }}' | merge-json -t "${tabSize:-4}" package.json -
