#!/usr/bin/env bats
# Covers configure-certs.sh's certificate lookup precedence and its
# no-op-with-warning behavior when certs or update-ca-certificates are missing.

FEATURE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    TEST_DIR=$(mktemp -d)
    ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    mkdir -p "$TEST_DIR/bin"
    cat >"$TEST_DIR/bin/zz_colors" <<'EOF'
#!/bin/sh
zz_log() { shift; echo "$@" >&2; }
EOF
    chmod +x "$TEST_DIR/bin/zz_colors"
    export PATH="$TEST_DIR/bin:$PATH"
    unset GATEWAY_CERTS_DIR
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

@test "configure-certs.sh: warns and exits 0 when no certificates found anywhere" {
    run sh "$FEATURE_DIR/configure-certs.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No gateway root CA certificate found"* ]]
}

@test "configure-certs.sh: prefers GATEWAY_CERTS_DIR over repo folder" {
    mkdir -p "$TEST_DIR/explicit" "$TEST_DIR/.devcontainer/.gateway/certs"
    touch "$TEST_DIR/explicit/explicit.pem"
    touch "$TEST_DIR/.devcontainer/.gateway/certs/repo.pem"
    export GATEWAY_CERTS_DIR="$TEST_DIR/explicit"

    cat >"$TEST_DIR/bin/update-ca-certificates" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$TEST_DIR/bin/update-ca-certificates"

    run sh "$FEATURE_DIR/configure-certs.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"$TEST_DIR/explicit"* ]]
}

@test "configure-certs.sh: warns and exits 0 when update-ca-certificates unavailable" {
    mkdir -p "$TEST_DIR/.devcontainer/.gateway/certs"
    touch "$TEST_DIR/.devcontainer/.gateway/certs/repo.pem"

    run env PATH="$TEST_DIR/bin:/usr/bin:/bin" sh "$FEATURE_DIR/configure-certs.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"update-ca-certificates not available"* ]]
}

@test "configure-certs.sh: fails when core script is missing" {
    mkdir -p "$TEST_DIR/.devcontainer/.gateway/certs"
    touch "$TEST_DIR/.devcontainer/.gateway/certs/repo.pem"
    cat >"$TEST_DIR/bin/update-ca-certificates" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$TEST_DIR/bin/update-ca-certificates"

    # Run from a copy with no stubs/ dir alongside it, so the core script lookup misses.
    cp "$FEATURE_DIR/configure-certs.sh" "$TEST_DIR/configure-certs.sh"
    run sh "$TEST_DIR/configure-certs.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Core script not found"* ]]
}
