#!/usr/bin/env bats

load helpers

setup() {
    setup_gateway_path
    STORE_DIR="$BATS_TEST_TMPDIR/store"
    CERTS_DIR="$BATS_TEST_TMPDIR/certs"
    mkdir -p "$STORE_DIR" "$CERTS_DIR"
    export CERT_STORE_DIR="$STORE_DIR"
    export UPDATE_CA_CMD="true"
}

teardown() {
    teardown_gateway_path
}

@test "missing certs dir: no-op, exit 0" {
    run install-certs-core "$BATS_TEST_TMPDIR/does-not-exist"
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$STORE_DIR")" ]
}

@test "empty certs dir: no-op, exit 0" {
    run install-certs-core "$CERTS_DIR"
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$STORE_DIR")" ]
}

@test "valid pem: installed into the trust store as .crt" {
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    run install-certs-core "$CERTS_DIR"
    [ "$status" -eq 0 ]
    [ -f "$STORE_DIR/gateway.crt" ]
    grep -q "gateway-test-root-ca" <(openssl x509 -in "$STORE_DIR/gateway.crt" -noout -subject)
}

@test "non-pem file: skipped, not copied" {
    echo "not a certificate" >"$CERTS_DIR/gateway.pem"
    run install-certs-core "$CERTS_DIR"
    [ "$status" -eq 0 ]
    [ ! -f "$STORE_DIR/gateway.crt" ]
}

@test "already installed and unchanged: no-op, still exit 0" {
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    install-certs-core "$CERTS_DIR"
    run install-certs-core "$CERTS_DIR"
    [ "$status" -eq 0 ]
    [ -f "$STORE_DIR/gateway.crt" ]
}

@test "update command missing: no-op, exit 0" {
    export UPDATE_CA_CMD="definitely-not-a-real-command"
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    run install-certs-core "$CERTS_DIR"
    [ "$status" -eq 0 ]
    [ ! -f "$STORE_DIR/gateway.crt" ]
}

@test "unwritable trust store: exit 1" {
    [ "$(id -u)" = "0" ] && skip "root bypasses permission checks"
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    chmod 555 "$STORE_DIR"
    run install-certs-core "$CERTS_DIR"
    chmod 755 "$STORE_DIR"
    [ "$status" -eq 1 ]
}
