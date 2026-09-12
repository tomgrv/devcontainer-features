#!/usr/bin/env bats

load helpers

setup() {
    setup_gateway_path
    BINDIR="$BATS_TEST_TMPDIR/bin"
    FAKE_CURL_DIR="$BATS_TEST_TMPDIR/fake-system-bin"
    mkdir -p "$BINDIR" "$FAKE_CURL_DIR"

    # A fake system curl, isolated on its own PATH entry, so divert never
    # touches the real one.
    cat >"$FAKE_CURL_DIR/curl" <<'EOF'
#!/bin/sh
echo "real curl $*"
EOF
    chmod +x "$FAKE_CURL_DIR/curl"
    export PATH="$FAKE_CURL_DIR:$PATH"
}

teardown() {
    teardown_gateway_path
}

@test "install: missing args, exit 1" {
    run install-curl-wrapper-core install
    [ "$status" -eq 1 ]
}

@test "install: copies wrapper as gateway-curl, executable" {
    run install-curl-wrapper-core install "$GATEWAY_STUB_DIR/gateway-curl.sh" "$BINDIR"
    [ "$status" -eq 0 ]
    [ -x "$BINDIR/gateway-curl" ]
}

@test "divert: missing bindir arg, exit 1" {
    run install-curl-wrapper-core divert
    [ "$status" -eq 1 ]
}

@test "divert: curl symlinked to wrapper, real curl kept as .real" {
    install-curl-wrapper-core install "$GATEWAY_STUB_DIR/gateway-curl.sh" "$BINDIR"
    curl_bin="$FAKE_CURL_DIR/curl"
    run install-curl-wrapper-core divert "$BINDIR"
    [ "$status" -eq 0 ]
    [ -x "${curl_bin}.real" ]
    [ "$(readlink -f "$curl_bin")" = "$BINDIR/gateway-curl" ]
}

@test "divert: idempotent when already diverted" {
    install-curl-wrapper-core install "$GATEWAY_STUB_DIR/gateway-curl.sh" "$BINDIR"
    install-curl-wrapper-core divert "$BINDIR"
    run install-curl-wrapper-core divert "$BINDIR"
    [ "$status" -eq 0 ]
}

@test "unknown mode: exit 1" {
    run install-curl-wrapper-core bogus
    [ "$status" -eq 1 ]
}
