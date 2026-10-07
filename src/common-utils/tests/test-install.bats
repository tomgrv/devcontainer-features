#!/usr/bin/env bats
# Covers install.sh's own remaining local logic: bootstrapping zz-use from
# tomgrv/scripts and creating the compatibility symlinks (zz-context,
# zz-dist, zz-edit, zz-json) that the rest of this monorepo still calls by
# their pre-split names. The zz-*/functional scripts themselves now live in
# and are tested by tomgrv/scripts.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_BIN=$(mktemp -d)
    export INSTALL_BIN_DIR="$TEST_BIN"
    export UTILS=""
}

teardown() {
    rm -rf "$TEST_BIN"
}

@test "install.sh: creates compatibility symlinks for renamed scripts" {
    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]

    [ -L "$TEST_BIN/zz-context" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz-context")")" = "feature-context" ]

    [ -L "$TEST_BIN/zz-dist" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz-dist")")" = "distribute-utils" ]

    [ -L "$TEST_BIN/zz-edit" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz-edit")")" = "edit-script" ]

    [ -L "$TEST_BIN/zz-json" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz-json")")" = "json-load" ]
}

@test "install.sh: installs yaml-merge, which feature-configure dispatches YAML stubs to" {
    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]

    [ -x "$TEST_BIN/yaml-merge" ]
}

@test "install.sh: is idempotent when zz-use is already on PATH" {
    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]

    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]
    [ -L "$TEST_BIN/zz-context" ]
}
