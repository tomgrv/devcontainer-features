#!/usr/bin/env bats
# Covers stubs/.husky/install.sh: installs the git-hook-* commands via
# zz-use (bootstrapping zz-use when missing) and runs husky, idempotently,
# from any entry point (npm prepare, devcontainer, Claude SessionStart).

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    git init -q
    mkdir -p .husky
    cp "$FEATURE_DIR/stubs/.husky/install.sh" .husky/install.sh

    # Every external command install.sh calls is stubbed to log its own
    # invocation; nothing real is downloaded or installed.
    STUB_BIN="$TEST_DIR/stub-bin"
    CALLS="$TEST_DIR/calls"
    mkdir -p "$STUB_BIN"
    for cmd in zz-use husky curl npm; do
        printf '#!/bin/sh\necho "%s $*" >>"%s"\n' "$cmd" "$CALLS" >"$STUB_BIN/$cmd"
        chmod +x "$STUB_BIN/$cmd"
    done
    # husky stub also sets core.hooksPath, like the real one
    echo 'git config core.hooksPath .husky/_' >>"$STUB_BIN/husky"
    export PATH="$STUB_BIN:$PATH"
    export INSTALL_BIN_DIR="$TEST_DIR/bin"
    unset CLAUDE_ENV_FILE HUSKY
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

@test "install.sh: installs git-hook-* commands and runs husky" {
    run sh .husky/install.sh
    [ "$status" -eq 0 ]
    grep -q '^zz-use .*git-hook-precommit' "$CALLS"
    grep -q '^zz-use .*git-hook-commitmsg' "$CALLS"
    grep -q '^husky' "$CALLS"
    [ "$(git config core.hooksPath)" = ".husky/_" ]
}

@test "install.sh: installs common-utils only when json-normalize is missing" {
    run sh .husky/install.sh
    grep -q '^npm install -g @tomgrv/devcontainer-features-common-utils' "$CALLS"

    : >"$CALLS"
    printf '#!/bin/sh\n' >"$STUB_BIN/json-normalize"
    chmod +x "$STUB_BIN/json-normalize"
    run sh .husky/install.sh
    ! grep -q '^npm install' "$CALLS"
}

@test "install.sh: skips husky when core.hooksPath already set" {
    git config core.hooksPath .husky/_
    run sh .husky/install.sh
    [ "$status" -eq 0 ]
    ! grep -q '^husky' "$CALLS"
}

@test "install.sh: bootstraps zz-use via curl only when missing" {
    run sh .husky/install.sh
    ! grep -q '^curl' "$CALLS"

    # hide any real zz-use installed on this machine
    rm "$STUB_BIN/zz-use"
    PATH="$STUB_BIN:/usr/bin:/bin" HOME="$TEST_DIR" run sh .husky/install.sh
    [ "$status" -eq 0 ]
    grep -q '^curl .*setup.sh' "$CALLS"
}

@test "install.sh: HUSKY=0 is a no-op" {
    HUSKY=0 run sh .husky/install.sh
    [ "$status" -eq 0 ]
    [ ! -s "$CALLS" ]
}

@test "install.sh: persists PATH to CLAUDE_ENV_FILE once" {
    export CLAUDE_ENV_FILE="$TEST_DIR/env"
    sh .husky/install.sh
    sh .husky/install.sh
    [ "$(grep -c 'export PATH=' "$CLAUDE_ENV_FILE")" -eq 1 ]
    grep -q "$INSTALL_BIN_DIR" "$CLAUDE_ENV_FILE"
}

@test "install.sh: exits 0 outside a git repository" {
    rm -rf .git
    run sh .husky/install.sh
    [ "$status" -eq 0 ]
    [ ! -s "$CALLS" ]
}

@test "install.sh: exits 0 even when husky fails" {
    printf '#!/bin/sh\nexit 1\n' >"$STUB_BIN/husky"
    run sh .husky/install.sh
    [ "$status" -eq 0 ]
}
