#!/bin/sh

# Runs lint-staged before `git commit`, so composer.json/package.json/etc.
# get validated and normalized on every commit made during a Claude Code
# session. Sessions clone the repo directly and never run the devcontainer
# postCreateCommand pipeline that would otherwise wire this up.
#
# Installs common-utils (normalize-json/etc., used by the lint-staged rules)
# on first run only; idempotent after that. Fires as a PreToolUse hook on
# Bash, filtered to `git commit` commands (see .claude/settings.json).

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

[ -f package.json ] || exit 0

if ! command -v normalize-json >/dev/null 2>&1 && [ -f src/common-utils/install.sh ]; then
    sh src/common-utils/install.sh >&2 || {
        echo "lint-staged-precommit.sh: common-utils install failed, skipping lint-staged" >&2
        exit 0
    }
fi

npx --yes lint-staged >&2
status=$?

if [ "$status" -ne 0 ]; then
    echo "lint-staged-precommit.sh: lint-staged failed (exit $status), blocking commit" >&2
    exit 2
fi
