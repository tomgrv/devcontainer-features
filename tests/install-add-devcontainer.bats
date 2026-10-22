#!/usr/bin/env bats
# `install.sh add <feature>` deploys the root devcontainer.json stub (and only
# that one: `init` is what lays down the other root stubs). Runs the real
# install.sh against a fake source tree whose install-feat.sh only records the
# feature it was asked to install, so no feature is actually installed.

REPO_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_BIN=$(mktemp -d)
    SRC=$(mktemp -d)
    WORK=$(mktemp -d)
    export INSTALL_BIN_DIR="$TEST_BIN"
    export INSTALLED="$SRC/installed.log"

    cp "$REPO_DIR/install.sh" "$SRC/install.sh"
    mkdir -p "$SRC/stubs/.devcontainer" "$SRC/stubs/.vscode"
    printf '{"image":"img","name":"stub","features":{"ghcr.io/tomgrv/devcontainer-features/githooks:11":{}}}\n' \
        >"$SRC/stubs/.devcontainer/devcontainer.json"
    printf '{}\n' >"$SRC/stubs/.vscode/settings.json"
    printf '#!/bin/sh\necho "$2" >>"$INSTALLED"\n' >"$SRC/install-feat.sh"

    cd "$WORK"
    git init -q
}

teardown() {
    rm -rf "$TEST_BIN" "$SRC" "$WORK"
}

@test "add: creates the root devcontainer.json from the stub" {
    run env PATH="$TEST_BIN:$PATH" sh "$SRC/install.sh" add myfeature
    [ "$status" -eq 0 ]

    [ "$(jq -r .image .devcontainer/devcontainer.json)" = img ]
    [ "$(cat "$INSTALLED")" = myfeature ]
}

@test "add: deploys only the devcontainer.json stub, not the other root stubs" {
    run env PATH="$TEST_BIN:$PATH" sh "$SRC/install.sh" add myfeature
    [ "$status" -eq 0 ]

    [ ! -e .vscode/settings.json ]
}

@test "add: merges into an existing devcontainer.json and keeps its own values" {
    mkdir .devcontainer
    printf '{"name":"mine","features":{"ghcr.io/devcontainers/features/node:1":{}}}\n' >.devcontainer/devcontainer.json

    run env PATH="$TEST_BIN:$PATH" sh "$SRC/install.sh" add myfeature
    [ "$status" -eq 0 ]

    [ "$(jq -r .name .devcontainer/devcontainer.json)" = mine ]
    [ "$(jq -r .image .devcontainer/devcontainer.json)" = img ]
    jq -e '.features | has("ghcr.io/devcontainers/features/node:1") and has("ghcr.io/tomgrv/devcontainer-features/githooks:11")' .devcontainer/devcontainer.json
}

@test "add: deploys the stub once however many features are added" {
    run env PATH="$TEST_BIN:$PATH" sh "$SRC/install.sh" add one two
    [ "$status" -eq 0 ]

    [ "$(grep -c '^one$\|^two$' "$INSTALLED")" -eq 2 ]
    [ "$(printf '%s\n' "$output" | grep -c 'Deployed .*devcontainer.json')" -eq 1 ]
}
