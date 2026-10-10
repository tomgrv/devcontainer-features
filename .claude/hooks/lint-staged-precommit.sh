#!/bin/sh

# Runs lint-staged before `git commit`, so composer.json/package.json/etc.
# get validated and normalized on every commit made during a Claude Code
# session. Sessions clone the repo directly and never run the devcontainer
# postCreateCommand pipeline that would otherwise wire this up.
#
# json-normalize (used by the lint-staged rules) ships in tomgrv/scripts,
# not in the common-utils npm package: it is installed with `zz-use json`.
# Fires as a PreToolUse hook on Bash (see .claude/settings.json); the
# `if` filter there is not honoured everywhere, so the command is also
# checked here, from the hook payload on stdin.

grep -q 'git commit' || exit 0

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

[ -f package.json ] || exit 0

# Real git hooks already active (githooks feature: husky + .husky/pre-commit
# running lint-staged) -- let git's own pre-commit do it, don't run twice.
case "$(git config core.hooksPath)" in
.husky*) [ -x .husky/pre-commit ] && exit 0 ;;
esac

if ! command -v json-normalize >/dev/null 2>&1; then
    [ -f .husky/install.sh ] && sh .husky/install.sh >&2
    command -v json-normalize >/dev/null 2>&1 || {
        echo "lint-staged-precommit.sh: json-normalize unavailable, skipping lint-staged" >&2
        exit 0
    }
fi

npx --yes lint-staged >&2
status=$?

if [ "$status" -ne 0 ]; then
    echo "lint-staged-precommit.sh: lint-staged failed (exit $status), blocking commit" >&2
    exit 2
fi
