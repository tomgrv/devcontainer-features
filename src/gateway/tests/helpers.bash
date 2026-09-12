#!/usr/bin/env bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATEWAY_DIR="$REPO_ROOT/src/gateway"
GATEWAY_STUB_DIR="$GATEWAY_DIR/stubs/.devcontainer/.gateway"

setup_gateway_path() {
    local file
    TEST_BIN=$(mktemp -d)
    for file in "$GATEWAY_STUB_DIR"/*.sh; do
        [ -f "$file" ] || continue
        chmod +x "$file"
        ln -sf "$file" "$TEST_BIN/$(basename "$file" .sh)"
    done
    export PATH="$TEST_BIN:$PATH"
}

teardown_gateway_path() {
    rm -rf "$TEST_BIN"
}

# Generates a throwaway self-signed root CA at $1/<name>.pem with subject CN=$2.
make_test_ca() {
    local dir="$1" name="$2" cn="$3"
    openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
        -subj "/CN=$cn" \
        -keyout "$dir/$name.key" -out "$dir/$name.pem" >/dev/null 2>&1
}
