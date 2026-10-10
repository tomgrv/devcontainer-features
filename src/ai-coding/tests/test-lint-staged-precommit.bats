#!/usr/bin/env bats
# Covers stubs/.claude/hooks/lint-staged-precommit.sh: only acts on
# `git commit` payloads, and skips (exit 0) instead of blocking when
# json-normalize cannot be installed.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    git init -q
    echo '{}' >package.json
    mkdir -p .claude/hooks .husky
    cp "$FEATURE_DIR/stubs/.claude/hooks/lint-staged-precommit.sh" .claude/hooks/

    STUB_BIN="$TEST_DIR/stub-bin"
    CALLS="$TEST_DIR/calls"
    mkdir -p "$STUB_BIN"
    for cmd in npx; do
        printf '#!/bin/sh\necho "%s $*" >>"%s"\n' "$cmd" "$CALLS" >"$STUB_BIN/$cmd"
        chmod +x "$STUB_BIN/$cmd"
    done
    export PATH="$STUB_BIN:$PATH"
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

payload() {
    printf '{"tool_input":{"command":"%s"}}' "$1"
}

@test "hook: ignores non-commit commands" {
    run sh -c "$(declare -f payload); payload 'ls -la' | sh .claude/hooks/lint-staged-precommit.sh"
    [ "$status" -eq 0 ]
    [ ! -e "$CALLS" ]
}

@test "hook: runs lint-staged on git commit and blocks on failure" {
    printf '#!/bin/sh\n' >"$STUB_BIN/json-normalize"
    chmod +x "$STUB_BIN/json-normalize"
    printf '#!/bin/sh\necho "npx $*" >>"%s"\nexit 1\n' "$CALLS" >"$STUB_BIN/npx"
    run sh -c "$(declare -f payload); payload 'git commit -m x' | sh .claude/hooks/lint-staged-precommit.sh"
    [ "$status" -eq 2 ]
    grep -q '^npx --yes lint-staged' "$CALLS"
}

@test "hook: skips without blocking when json-normalize cannot be installed" {
    run sh -c "$(declare -f payload); payload 'git commit -m x' | sh .claude/hooks/lint-staged-precommit.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"json-normalize unavailable"* ]]
    [ ! -e "$CALLS" ]
}
