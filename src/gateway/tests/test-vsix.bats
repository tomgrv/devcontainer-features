#!/usr/bin/env bats

load helpers

setup() {
    VSIX="$GATEWAY_DIR/bin/gateway-vsix.sh"
    CACHE="$BATS_TEST_TMPDIR/cache"
    export GATEWAY_VSIX_DIR="$CACHE"
    export GATEWAY_VSIX_PREFETCH="$BATS_TEST_TMPDIR/prefetch"
    export GATEWAY_VSIX_PLATFORM=linux-x64
    export GATEWAY_VSIX_TIMEOUT=2
    export GATEWAY_VSIX_POLL=1
    export CURL_LOG="$BATS_TEST_TMPDIR/curl.log"
    export CLI_LOG="$BATS_TEST_TMPDIR/cli.log"

    # Fake curl: logs the URL, writes a zip-looking body unless the URL
    # matches $CURL_FAIL (then fails like curl -f would)
    FAKE_CURL="$BATS_TEST_TMPDIR/fake-curl"
    cat >"$FAKE_CURL" <<'EOF'
#!/bin/sh
out="" url=""
while [ $# -gt 0 ]; do
    case "$1" in
    -o) out="$2"; shift ;;
    http*) url="$1" ;;
    esac
    shift
done
echo "$url" >>"$CURL_LOG"
if [ -n "${CURL_FAIL:-}" ] && echo "$url" | grep -q "$CURL_FAIL"; then
    exit 22
fi
printf 'PK\003\004%s' "${CURL_BODY:-}" >"$out"
EOF
    chmod +x "$FAKE_CURL"
    export GATEWAY_VSIX_CURL="$FAKE_CURL"

    # Fake VS Code server CLI: logs its arguments
    FAKE_CLI="$BATS_TEST_TMPDIR/code-server"
    cat >"$FAKE_CLI" <<'EOF'
#!/bin/sh
[ "$1" = "--version" ] && exit 0
echo "$*" >>"$CLI_LOG"
EOF
    chmod +x "$FAKE_CLI"
}

@test "fetch: downloads platform build into <dir>/<id>.vsix, lowercased" {
    run sh "$VSIX" fetch "$CACHE" Foo.Bar
    [ "$status" -eq 0 ]
    [ -f "$CACHE/foo.bar.vsix" ]
    grep -qF "publishers/Foo/vsextensions/Bar/latest/vspackage?targetPlatform=linux-x64" "$CURL_LOG"
}

@test "fetch: pinned version goes into the URL" {
    run sh "$VSIX" fetch "$CACHE" foo.bar@1.2.3
    [ "$status" -eq 0 ]
    grep -q "vsextensions/bar/1.2.3/vspackage" "$CURL_LOG"
}

@test "fetch: falls back to the universal package when no platform build" {
    CURL_FAIL=targetPlatform run sh "$VSIX" fetch "$CACHE" foo.bar
    [ "$status" -eq 0 ]
    [ -f "$CACHE/foo.bar.vsix" ]
    [ "$(tail -n1 "$CURL_LOG")" = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/foo/vsextensions/bar/latest/vspackage" ]
}

@test "fetch: rejects a non-zip body (gateway form, error page), exit 1" {
    cat >"$FAKE_CURL" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do [ "$1" = "-o" ] && echo "<html>gateway.zscaler</html>" >"$2"; shift; done
EOF
    run sh "$VSIX" fetch "$CACHE" foo.bar
    [ "$status" -eq 1 ]
    [ ! -e "$CACHE/foo.bar.vsix" ]
    [ ! -e "$CACHE/foo.bar.vsix.part" ]
}

@test "fetch: keeps going after a failure, exit 1" {
    CURL_FAIL=/bad/ run sh "$VSIX" fetch "$CACHE" foo.bad foo.good
    [ "$status" -eq 1 ]
    [ -f "$CACHE/foo.good.vsix" ]
}

@test "fetch: skips cached, removal-syntax and rejects invalid ids" {
    mkdir -p "$CACHE"
    printf 'PK' >"$CACHE/foo.bar.vsix"
    run sh "$VSIX" fetch "$CACHE" foo.bar -foo.removed
    [ "$status" -eq 0 ]
    [ ! -e "$CURL_LOG" ]

    run sh "$VSIX" fetch "$CACHE" nodot
    [ "$status" -eq 1 ]
}

@test "fetch: honours a custom URL template" {
    GATEWAY_VSIX_URL="https://open-vsx.org/api/{publisher}/{name}/{version}/file/{publisher}.{name}-{version}.vsix" \
        run sh "$VSIX" fetch "$CACHE" foo.bar@1.0.0
    [ "$status" -eq 0 ]
    grep -qx "https://open-vsx.org/api/foo/bar/1.0.0/file/foo.bar-1.0.0.vsix?targetPlatform=linux-x64" "$CURL_LOG"
}

@test "ids: lists devcontainer.json extensions, tolerating // comments" {
    cat >"$BATS_TEST_TMPDIR/devcontainer.json" <<'EOF'
{
    // comment
    "customizations": { "vscode": { "extensions": ["a.b", "c.d@1.0.0"] } }
}
EOF
    run sh "$VSIX" ids "$BATS_TEST_TMPDIR/devcontainer.json"
    [ "$status" -eq 0 ]
    [ "$output" = "a.b
c.d@1.0.0" ]
}

@test "ids: missing file, no output" {
    run sh "$VSIX" ids "$BATS_TEST_TMPDIR/none.json"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "install: one CLI call with every cached VSIX" {
    mkdir -p "$CACHE" "$GATEWAY_VSIX_PREFETCH"
    printf 'PK' >"$CACHE/a.b.vsix"
    printf 'PK' >"$GATEWAY_VSIX_PREFETCH/c.d.vsix"
    run sh "$VSIX" install "$FAKE_CLI" "$GATEWAY_VSIX_PREFETCH" "$CACHE"
    [ "$status" -eq 0 ]
    [ "$(cat "$CLI_LOG")" = "--install-extension $GATEWAY_VSIX_PREFETCH/c.d.vsix --install-extension $CACHE/a.b.vsix" ]
}

@test "install: nothing cached, CLI not called" {
    run sh "$VSIX" install "$FAKE_CLI" "$CACHE"
    [ "$status" -eq 0 ]
    [ ! -e "$CLI_LOG" ]
}

@test "sync: fetches what devcontainer.json lists beyond the prefetch, then installs all" {
    mkdir -p "$BATS_TEST_TMPDIR/ws/.devcontainer" "$GATEWAY_VSIX_PREFETCH"
    printf 'PK' >"$GATEWAY_VSIX_PREFETCH/a.b.vsix"
    echo '{"customizations":{"vscode":{"extensions":["a.b","c.d"]}}}' >"$BATS_TEST_TMPDIR/ws/.devcontainer/devcontainer.json"
    cd "$BATS_TEST_TMPDIR/ws"
    GATEWAY_VSIX_CLI="$FAKE_CLI" run sh "$VSIX" sync
    [ "$status" -eq 0 ]
    [ "$(wc -l <"$CURL_LOG")" -eq 1 ]
    grep -q "vsextensions/d/" "$CURL_LOG"
    [ "$(cat "$CLI_LOG")" = "--install-extension $GATEWAY_VSIX_PREFETCH/a.b.vsix --install-extension $CACHE/c.d.vsix" ]
}

@test "sync: nothing to provision, returns without waiting for the server" {
    cd "$BATS_TEST_TMPDIR"
    GATEWAY_VSIX_TIMEOUT=60 run timeout 10 sh "$VSIX" sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nothing to provision"* ]]
}

@test "sync: gives up when no VS Code server shows up, exit 1" {
    mkdir -p "$GATEWAY_VSIX_PREFETCH"
    printf 'PK' >"$GATEWAY_VSIX_PREFETCH/a.b.vsix"
    cd "$BATS_TEST_TMPDIR"
    HOME="$BATS_TEST_TMPDIR" run sh "$VSIX" sync
    [ "$status" -eq 1 ]
    [ ! -e "$CLI_LOG" ]
}

@test "sync: picks up the VS Code server CLI once it appears under HOME" {
    mkdir -p "$GATEWAY_VSIX_PREFETCH"
    printf 'PK' >"$GATEWAY_VSIX_PREFETCH/a.b.vsix"
    server="$BATS_TEST_TMPDIR/.vscode-server/cli/servers/Stable-abc/server/bin"
    mkdir -p "$server"
    cp "$FAKE_CLI" "$server/code-server"
    cd "$BATS_TEST_TMPDIR"
    HOME="$BATS_TEST_TMPDIR" run sh "$VSIX" sync
    [ "$status" -eq 0 ]
    [ "$(cat "$CLI_LOG")" = "--install-extension $GATEWAY_VSIX_PREFETCH/a.b.vsix" ]
}

@test "unknown command: usage, exit 1" {
    run sh "$VSIX" bogus
    [ "$status" -eq 1 ]
    [[ "$output" == *"gateway-vsix fetch"* ]]
}

@test "ids: recurses into local and OCI features and their dependsOn, once each" {
    ws="$BATS_TEST_TMPDIR/ws/.devcontainer"
    mkdir -p "$ws/local"
    cat >"$ws/devcontainer.json" <<'JSON'
{
    // root
    "features": { "reg.io/o/r/a:1": {}, "./local": {} },
    "customizations": { "vscode": { "extensions": ["root.ext", "-b.removed"] } }
}
JSON
    echo '{"customizations":{"vscode":{"extensions":["local.ext"]}}}' >"$ws/local/devcontainer-feature.json"

    # Fake registry: bearer challenge, token endpoint, manifests with metadata
    # annotations; feature a depends on b, b depends back on a (cycle)
    cat >"$FAKE_CURL" <<'SH'
#!/bin/sh
head=0 auth="" url=""
while [ $# -gt 0 ]; do
    case "$1" in
    -sI) head=1 ;;
    -H) case "$2" in Authorization:*) auth="$2" ;; esac; shift ;;
    http*) url="$1" ;;
    esac
    shift
done
echo "$url $auth" >>"$CURL_LOG"
if [ "$head" = 1 ]; then
    printf 'HTTP/1.1 401\r\nWWW-Authenticate: Bearer realm="https://reg.io/token",service="reg.io",scope="pull"\r\n\r\n'
    exit 0
fi
case "$url" in
*/token*) echo '{"token":"t0k"}' ;;
*/o/r/a/manifests/1)
    [ "$auth" = "Authorization: Bearer t0k" ] || exit 22
    jq -n --arg m '{"dependsOn":{"reg.io/o/r/b:2":{}},"customizations":{"vscode":{"extensions":["a.ext","root.ext"]}}}' '{annotations:{"dev.containers.metadata":$m}}' ;;
*/o/r/b/manifests/2)
    jq -n --arg m '{"dependsOn":{"reg.io/o/r/a:1":{}},"customizations":{"vscode":{"extensions":["b.ext","b.removed"]}}}' '{annotations:{"dev.containers.metadata":$m}}' ;;
*) exit 22 ;;
esac
SH
    run sh "$VSIX" ids "$ws/devcontainer.json"
    [ "$status" -eq 0 ]
    [ "$output" = "root.ext
local.ext
a.ext
b.ext" ]
    [ "$(grep -c '/o/r/a/manifests/1 Authorization' "$CURL_LOG")" -eq 1 ]
}

@test "ids: unreachable feature metadata is skipped, not fatal" {
    echo '{"features":{"reg.io/o/r/gone:1":{},"legacy/repo/feat":{}},"customizations":{"vscode":{"extensions":["root.ext"]}}}' \
        >"$BATS_TEST_TMPDIR/devcontainer.json"
    printf '#!/bin/sh\nexit 22\n' >"$FAKE_CURL"
    run sh "$VSIX" ids "$BATS_TEST_TMPDIR/devcontainer.json"
    [ "$status" -eq 0 ]
    [[ "$output" == *"root.ext"* ]]
    [[ "$output" == *"No metadata for feature reg.io/o/r/gone:1"* ]]
}
