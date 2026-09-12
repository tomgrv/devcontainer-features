#!/usr/bin/env bats

load helpers

setup() {
    command -v docker >/dev/null 2>&1 || skip "docker not available"
    docker info >/dev/null 2>&1 || skip "docker daemon not reachable"
    STUB_DIR="$GATEWAY_STUB_DIR"
    CERTS_DIR="$STUB_DIR/certs"
    IMG_WITH_CA="gateway-feature-test-with-ca"
    IMG_NO_CA="gateway-feature-test-no-ca"
    rm -f "$CERTS_DIR"/*.pem "$CERTS_DIR"/*.key
}

teardown() {
    rm -f "$CERTS_DIR"/*.pem "$CERTS_DIR"/*.key
    docker rmi "$IMG_WITH_CA" "$IMG_NO_CA" >/dev/null 2>&1 || true
}

@test "image build bakes the gateway root CA into the trust store" {
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    run docker build --tag "$IMG_WITH_CA" --file "$STUB_DIR/Dockerfile" "$STUB_DIR"
    [ "$status" -eq 0 ]

    run docker run --rm "$IMG_WITH_CA" sh -c '[ -f /usr/local/share/ca-certificates/gateway.crt ]'
    [ "$status" -eq 0 ]

    run docker run --rm "$IMG_WITH_CA" sh -c \
        'openssl x509 -in /usr/local/share/ca-certificates/gateway.crt -noout -subject'
    [ "$status" -eq 0 ]
    [[ "$output" == *"gateway-test-root-ca"* ]]
}

@test "image build diverts curl to the gateway-curl wrapper, before any feature runs" {
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    run docker build --tag "$IMG_WITH_CA" --file "$STUB_DIR/Dockerfile" "$STUB_DIR"
    [ "$status" -eq 0 ]

    run docker run --rm "$IMG_WITH_CA" sh -c 'readlink -f "$(command -v curl)"'
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/local/bin/gateway-curl" ]

    run docker run --rm "$IMG_WITH_CA" sh -c '[ -x /usr/bin/curl.real ]'
    [ "$status" -eq 0 ]
}

@test "image build sets CA env vars for tools that ignore the OS trust store" {
    make_test_ca "$CERTS_DIR" gateway gateway-test-root-ca
    run docker build --tag "$IMG_WITH_CA" --file "$STUB_DIR/Dockerfile" "$STUB_DIR"
    [ "$status" -eq 0 ]

    for var in NODE_EXTRA_CA_CERTS CURL_CA_BUNDLE SSL_CERT_FILE REQUESTS_CA_BUNDLE GIT_SSL_CAINFO COMPOSER_CA_FILE; do
        run docker run --rm "$IMG_WITH_CA" sh -c "echo \"\$$var\""
        [ "$status" -eq 0 ]
        [ "$output" = "/etc/ssl/certs/ca-certificates.crt" ]
    done
}

@test "image build degrades gracefully with no certificate present" {
    run docker build --tag "$IMG_NO_CA" --file "$STUB_DIR/Dockerfile" "$STUB_DIR"
    [ "$status" -eq 0 ]

    run docker run --rm "$IMG_NO_CA" sh -c 'readlink -f "$(command -v curl)"'
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/local/bin/gateway-curl" ]

    run docker run --rm "$IMG_NO_CA" sh -c 'curl --version | head -n1'
    [ "$status" -eq 0 ]
    [[ "$output" == *curl* ]]
}
