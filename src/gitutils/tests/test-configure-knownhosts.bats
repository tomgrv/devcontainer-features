#!/usr/bin/env bats
# Covers configure-knownhosts.sh's graceful no-op when ssh-keyscan (openssh-client) is missing.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    git init -q
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"

    # Isolated PATH with only what the script needs, minus ssh-keyscan,
    # so this passes even on hosts (like CI) that have openssh-client installed.
    NO_SSH_BIN="$TEST_DIR/no-ssh-bin"
    mkdir -p "$NO_SSH_BIN"
    for tool in sh git mkdir chmod timeout cat; do
        ln -s "$(command -v "$tool")" "$NO_SSH_BIN/$tool"
    done
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

@test "configure-knownhosts.sh: exits 0 without writing known_hosts when ssh-keyscan is missing" {
    run env PATH="$NO_SSH_BIN" sh "$FEATURE_DIR/configure-knownhosts.sh"
    [ "$status" -eq 0 ]
    [ ! -f "$HOME/.ssh/known_hosts" ]
}

@test "configure-knownhosts.sh: writes known_hosts when ssh-keyscan is present" {
    mkdir -p "$TEST_DIR/bin"
    cat >"$TEST_DIR/bin/ssh-keyscan" <<'EOF'
#!/bin/sh
echo "github.com fake-key"
EOF
    chmod +x "$TEST_DIR/bin/ssh-keyscan"

    run env PATH="$TEST_DIR/bin:/usr/bin:/bin" sh "$FEATURE_DIR/configure-knownhosts.sh"
    [ "$status" -eq 0 ]
    [[ "$(cat "$HOME/.ssh/known_hosts")" == *"fake-key"* ]]
}
