#!/usr/bin/env bats
# Covers install.sh's own remaining local logic: bootstrapping zz_use from
# tomgrv/scripts and creating the compatibility shims (zz_feature, zz_context,
# zz_dist, zz_edit, zz_json) that the rest of this monorepo still calls by
# their pre-split names. The zz_*/functional scripts themselves now live in
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

@test "install.sh: creates zz_feature shim dispatching -i/-c" {
    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]
    [ -x "$TEST_BIN/zz_feature" ]

    run env PATH="$TEST_BIN:$PATH" "$TEST_BIN/zz_feature"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: zz_feature -i|-c"* ]]
}

@test "install.sh: creates compatibility symlinks for renamed scripts" {
    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]

    [ -L "$TEST_BIN/zz_context" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz_context")")" = "resolve-context" ]

    [ -L "$TEST_BIN/zz_dist" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz_dist")")" = "distribute-utils" ]

    [ -L "$TEST_BIN/zz_edit" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz_edit")")" = "edit-script" ]

    [ -L "$TEST_BIN/zz_json" ]
    [ "$(basename "$(readlink -f "$TEST_BIN/zz_json")")" = "load-json" ]
}

@test "install.sh: is idempotent when zz_use is already on PATH" {
    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]

    run env PATH="$TEST_BIN:$PATH" sh "$FEATURE_DIR/install.sh"
    [ "$status" -eq 0 ]
    [ -x "$TEST_BIN/zz_feature" ]
}
