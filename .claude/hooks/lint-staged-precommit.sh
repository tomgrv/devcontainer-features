#!/bin/sh

# Runs lint-staged before `git commit`, so composer.json/package.json/etc.
# get validated and normalized on every commit made during a Claude Code
# session. Sessions clone the repo directly and never run the devcontainer
# postCreateCommand pipeline that would otherwise wire this up.
#
# common-utils (normalize-json/etc., used by the lint-staged rules) is
# fetched via `npm install` -- it's a published npm package
# (@tomgrv-devcontainer-features/common-utils, declared as an
# optionalDependency in package.json), not a local script. Fires as a
# PreToolUse hook on Bash, filtered to `git commit` commands (see
# .claude/settings.json).

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

[ -f package.json ] || exit 0

if [ ! -x node_modules/.bin/normalize-json ]; then
    npm install --no-audit --no-fund >&2 || {
        echo "lint-staged-precommit.sh: npm install failed, skipping lint-staged" >&2
        exit 0
    }
fi

npx --yes lint-staged >&2
status=$?

if [ "$status" -ne 0 ]; then
    echo "lint-staged-precommit.sh: lint-staged failed (exit $status), blocking commit" >&2
    exit 2
fi
