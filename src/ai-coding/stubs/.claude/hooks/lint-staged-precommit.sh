#!/bin/sh

# Runs lint-staged before `git commit`, so composer.json/package.json/etc.
# get validated and normalized on every commit made during a Claude Code
# session. Sessions clone the repo directly and never run the devcontainer
# postCreateCommand pipeline that would otherwise wire this up.
#
# normalize-json (used by the lint-staged rules) comes from
# https://github.com/tomgrv/scripts via zz_use -- it does not rely on this
# repo's package.json declaring common-utils as a dependency, or on npm
# workspace linking. Fires as a PreToolUse hook on Bash, filtered to
# `git commit` commands (see .claude/settings.json).

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

[ -f package.json ] || exit 0

if ! command -v normalize-json >/dev/null 2>&1; then
    if ! command -v zz_use >/dev/null 2>&1; then
        _zz_setup_tmp=$(mktemp) || exit 0
        if ! curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" -o "$_zz_setup_tmp" >&2; then
            echo "lint-staged-precommit.sh: failed to download the zz_use bootstrap, skipping lint-staged" >&2
            rm -f "$_zz_setup_tmp"
            exit 0
        fi
        sh "$_zz_setup_tmp" >&2
        _zz_setup_rc=$?
        rm -f "$_zz_setup_tmp"
        [ "$_zz_setup_rc" -eq 0 ] || {
            echo "lint-staged-precommit.sh: zz_use bootstrap failed, skipping lint-staged" >&2
            exit 0
        }
    fi
    export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"
    zz_use normalize-json >&2 || {
        echo "lint-staged-precommit.sh: zz_use normalize-json failed, skipping lint-staged" >&2
        exit 0
    }
fi

npx --yes lint-staged >&2
status=$?

if [ "$status" -ne 0 ]; then
    echo "lint-staged-precommit.sh: lint-staged failed (exit $status), blocking commit" >&2
    exit 2
fi
