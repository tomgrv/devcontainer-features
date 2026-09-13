#!/usr/bin/env bats
# Covers configure-hooks.sh generating .husky/<hookname> wrapper scripts
# that delegate to the corresponding git-hook-<name> command.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    git init -q

    # zz_log is provided at runtime by common-utils (zz_use); stub it here
    # as a no-op executable so the scripts run standalone under bats.
    STUB_BIN="$TEST_DIR/stub-bin"
    mkdir -p "$STUB_BIN"
    cat >"$STUB_BIN/zz_log" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$STUB_BIN/zz_log"
    export PATH="$STUB_BIN:$PATH"
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

@test "configure-hooks.sh: generates a wrapper for every migrated hook" {
    run sh "$FEATURE_DIR/configure-hooks.sh"
    [ "$status" -eq 0 ]

    for hook in pre-commit prepare-commit-msg commit-msg post-checkout post-merge pre-push; do
        [ -f ".husky/$hook" ]
    done
}

@test "configure-hooks.sh: generated wrappers are executable" {
    run sh "$FEATURE_DIR/configure-hooks.sh"
    [ "$status" -eq 0 ]

    for hook in pre-commit prepare-commit-msg commit-msg post-checkout post-merge pre-push; do
        [ -x ".husky/$hook" ]
    done
}

@test "configure-hooks.sh: each wrapper calls the matching git-hook-<name> command with args passed through" {
    run sh "$FEATURE_DIR/configure-hooks.sh"
    [ "$status" -eq 0 ]

    [[ "$(cat .husky/pre-commit)" == *'git-hook-precommit "$@"'* ]]
    [[ "$(cat .husky/prepare-commit-msg)" == *'git-hook-preparecommitmsg "$@"'* ]]
    [[ "$(cat .husky/commit-msg)" == *'git-hook-commitmsg "$@"'* ]]
    [[ "$(cat .husky/post-checkout)" == *'git-hook-postcheckout "$@"'* ]]
    [[ "$(cat .husky/post-merge)" == *'git-hook-postmerge "$@"'* ]]
    [[ "$(cat .husky/pre-push)" == *'git-hook-prepush "$@"'* ]]
}

@test "configure-hooks.sh: does not set core.hooksPath itself" {
    run sh "$FEATURE_DIR/configure-hooks.sh"
    [ "$status" -eq 0 ]

    run git config core.hooksPath
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "configure-hooks.sh: no-op outside a git repository" {
    cd "$TEST_DIR"
    rm -rf .git
    run sh "$FEATURE_DIR/configure-hooks.sh"
    [ "$status" -eq 0 ]
    [ ! -d .husky ]
}
