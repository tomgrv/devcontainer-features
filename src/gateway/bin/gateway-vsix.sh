#!/bin/sh

# Provision VS Code extensions (VSIX) with curl, then hand them to the VS Code
# server once it shows up.
#
# The VS Code server downloads extensions with Node's own http stack: it never
# goes through curl, so the gateway-curl wrapper cannot answer the SSL
# inspection gateway's interception form on its behalf, and every Marketplace
# download fails. This script fetches the VSIX packages with curl instead
# (i.e. through gateway-curl), and installs them from disk with the server's
# own CLI, which then never needs to reach the Marketplace.
#
# Usage:
#   gateway-vsix fetch <dir> <publisher.name[@version]>...
#       Download each extension into <dir>/<publisher.name>.vsix (skipped when
#       already there). Ids prefixed with "-" (devcontainer.json removal
#       syntax) are ignored.
#   gateway-vsix ids [devcontainer.json]
#       Print customizations.vscode.extensions from a devcontainer.json
#       (default: .devcontainer/devcontainer.json) and, recursively, from every
#       feature it references and their dependsOn: OCI features through their
#       registry manifest ("dev.containers.metadata" annotation), local ./
#       features from disk. "-publisher.name" entries remove an extension.
#       Full-line // comments are tolerated, block comments and trailing
#       commas are not.
#   gateway-vsix install <cli> <dir>...
#       Install every *.vsix found in <dir>... with the VS Code server <cli>.
#   gateway-vsix sync
#       The whole flow, meant to run in the background while VS Code attaches:
#       fetch whatever devcontainer.json lists and isn't cached yet, wait for
#       the VS Code server CLI to appear, then install everything cached.
#
# Environment variables:
#   GATEWAY_VSIX_DIR       Runtime download cache (default: ~/.cache/gateway/vsix)
#   GATEWAY_VSIX_PREFETCH  Build-time cache, read-only here (default: /usr/local/share/gateway/vsix)
#   GATEWAY_VSIX_CURL      curl command (default: gateway-curl when on PATH, else curl)
#   GATEWAY_VSIX_URL       Download URL template, {publisher} {name} {version}
#                          placeholders (default: Visual Studio Marketplace)
#   GATEWAY_VSIX_PLATFORM  Target platform (default: derived from the OS/arch)
#   GATEWAY_VSIX_CLI       VS Code server CLI (default: auto-detected)
#   GATEWAY_VSIX_TIMEOUT   Seconds to wait for the VS Code server (default: 900)

PREFETCH_DIR="${GATEWAY_VSIX_PREFETCH:-/usr/local/share/gateway/vsix}"
CACHE_DIR="${GATEWAY_VSIX_DIR:-${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}/gateway/vsix}"
# Not a ${:-} default: its "}" placeholders would close the expansion early
URL_TEMPLATE="$GATEWAY_VSIX_URL"
[ -n "$URL_TEMPLATE" ] || URL_TEMPLATE="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/{publisher}/vsextensions/{name}/{version}/vspackage"

log() {
    echo "[gateway-vsix] $*" >&2
}

resolve_curl() {
    if [ -n "${GATEWAY_VSIX_CURL:-}" ]; then
        echo "$GATEWAY_VSIX_CURL"
    elif command -v gateway-curl >/dev/null 2>&1; then
        echo gateway-curl
    else
        echo curl
    fi
}

# Marketplace target platform of this machine, empty when unknown
resolve_platform() {
    if [ -n "${GATEWAY_VSIX_PLATFORM+x}" ]; then
        echo "$GATEWAY_VSIX_PLATFORM"
        return
    fi
    os=linux
    [ -f /etc/alpine-release ] && os=alpine
    case "$(uname -m)" in
    x86_64 | amd64) echo "$os-x64" ;;
    aarch64 | arm64) echo "$os-arm64" ;;
    armv7l | armhf) echo "$os-armhf" ;;
    esac
}

# A VSIX is a zip archive: anything else is an error page or a gateway form
is_vsix() {
    [ -s "$1" ] && [ "$(head -c2 "$1")" = "PK" ]
}

vsix_name() {
    echo "${1%%@*}" | tr '[:upper:]' '[:lower:]'
}

download() {
    tmp="$2.part"
    # No -S: a 404 on the platform-specific probe is expected, not an error
    if "$CURL" -fsL --compressed --retry 2 -o "$tmp" "$1" 2>/dev/null && is_vsix "$tmp"; then
        # gateway-curl writes through mktemp (0600): keep it readable by the remote user
        mv "$tmp" "$2" && chmod 644 "$2"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

fetch() {
    dir="$1"
    shift
    [ -n "$dir" ] || {
        log "Usage: gateway-vsix fetch <dir> <publisher.name[@version]>..."
        return 1
    }
    mkdir -p "$dir" || return 1

    CURL=$(resolve_curl)
    platform=$(resolve_platform)
    rc=0

    for spec in "$@"; do
        case "$spec" in
        "" | -*) continue ;;
        esac

        id="${spec%%@*}"
        version=latest
        [ "$id" != "$spec" ] && version="${spec#*@}"
        publisher="${id%%.*}"
        name="${id#*.}"
        if [ -z "$publisher" ] || [ -z "$name" ] || [ "$name" = "$id" ]; then
            log "Invalid extension id: $spec"
            rc=1
            continue
        fi

        file="$dir/$(vsix_name "$id").vsix"
        if is_vsix "$file"; then
            log "$id already cached"
            continue
        fi

        url=$(echo "$URL_TEMPLATE" | sed -e "s|{publisher}|$publisher|g" -e "s|{name}|$name|g" -e "s|{version}|$version|g")
        case "$url" in
        *\?*) sep="&" ;;
        *) sep="?" ;;
        esac

        # Platform-specific build first, universal package as a fallback
        if { [ -n "$platform" ] && download "$url${sep}targetPlatform=$platform" "$file"; } || download "$url" "$file"; then
            log "$id fetched"
        else
            log "$id could not be fetched from $url"
            rc=1
        fi
    done
    return $rc
}

# devcontainer-feature.json of a feature reference, on stdout
feature_meta() {
    ref="$1"
    case "$ref" in
    ./* | ../*)
        sed 's#^[[:space:]]*//.*$##' "$2/$ref/devcontainer-feature.json" 2>/dev/null
        return
        ;;
    esac

    registry="${ref%%/*}"
    path="${ref#*/}"
    case "$registry" in
    *.* | *:* | localhost) ;;
    *) return 1 ;; # legacy GitHub-release feature id, no manifest to read
    esac
    case "$path" in
    *@*) repo="${path%@*}" tag="${path#*@}" ;;
    *:*) repo="${path%:*}" tag="${path##*:}" ;;
    *) repo="$path" tag=latest ;;
    esac

    url="https://$registry/v2/$repo/manifests/$tag"
    accept="Accept: application/vnd.oci.image.manifest.v1+json"

    # Anonymous pull token, as advertised by the registry's challenge
    auth="X-Anonymous: 1"
    challenge=$("$CURL" -sI -H "$accept" "$url" 2>/dev/null | tr -d '\r' | sed -n 's/^[Ww][Ww][Ww]-[Aa]uthenticate: *Bearer *//p')
    if [ -n "$challenge" ]; then
        realm=$(echo "$challenge" | sed -n 's/.*realm="\([^"]*\)".*/\1/p')
        service=$(echo "$challenge" | sed -n 's/.*service="\([^"]*\)".*/\1/p')
        scope=$(echo "$challenge" | sed -n 's/.*scope="\([^"]*\)".*/\1/p')
        token=$("$CURL" -fsS "$realm?service=$service&scope=$scope" 2>/dev/null | jq -r '.token // .access_token // empty')
        [ -n "$token" ] && auth="Authorization: Bearer $token"
    fi

    "$CURL" -fsS -H "$accept" -H "$auth" "$url" 2>/dev/null |
        jq -r '.annotations["dev.containers.metadata"] // empty'
}

ids() {
    file="${1:-.devcontainer/devcontainer.json}"
    [ -f "$file" ] || return 0
    base=$(dirname "$file")
    CURL=$(resolve_curl)

    # Breadth-first over features and their dependsOn, each visited once
    json=$(sed 's#^[[:space:]]*//.*$##' "$file")
    queue=""
    seen=""
    while :; do
        printf '%s' "$json" | jq -r '.customizations.vscode.extensions[]? | select(type == "string")' 2>/dev/null

        for ref in $(printf '%s' "$json" | jq -r '(.features // {}), (.dependsOn // {}) | keys[]' 2>/dev/null); do
            case " $seen " in
            *" $ref "*) continue ;;
            esac
            seen="$seen $ref"
            queue="$queue $ref"
        done

        # shellcheck disable=SC2086 # one word per feature reference
        set -- $queue
        [ $# -gt 0 ] || break
        ref="$1"
        shift
        queue="$*"

        json=$(feature_meta "$ref" "$base")
        [ -n "$json" ] || log "No metadata for feature $ref, its extensions are skipped"
    done | awk '
        /^-/ { removed[tolower(substr($0, 2))] = 1; next }
        { id = tolower($0); sub(/@.*/, "", id); if (!(($0) in listed)) { listed[$0] = 1; order[++n] = $0; key[n] = id } }
        END { for (i = 1; i <= n; i++) if (!(key[i] in removed)) print order[i] }'
}

# Newest VS Code server CLI found on this machine, if any
server_cli() {
    # shellcheck disable=SC2086 # globs are meant to expand here
    ls -td \
        "$HOME"/.vscode-server/cli/servers/*/server/bin/code-server \
        "$HOME"/.vscode-server/bin/*/bin/code-server \
        "$HOME"/.vscode-server-insiders/cli/servers/*/server/bin/code-server-insiders \
        "$HOME"/.vscode-server-insiders/bin/*/bin/code-server-insiders \
        /vscode/bin/*/*/bin/code-server* \
        2>/dev/null | head -n1
}

# Wait until the server CLI exists and actually runs (it can show up before
# its archive has finished extracting)
wait_cli() {
    deadline=$(($(date +%s) + ${GATEWAY_VSIX_TIMEOUT:-900}))
    while :; do
        cli="${GATEWAY_VSIX_CLI:-$(server_cli)}"
        if [ -n "$cli" ] && [ -x "$cli" ] && "$cli" --version >/dev/null 2>&1; then
            echo "$cli"
            return 0
        fi
        [ "$(date +%s)" -ge "$deadline" ] && return 1
        sleep "${GATEWAY_VSIX_POLL:-2}"
    done
}

install() {
    cli="$1"
    shift
    [ -n "$cli" ] || {
        log "Usage: gateway-vsix install <cli> <dir>..."
        return 1
    }

    set -- $(for dir in "$@"; do
        for vsix in "$dir"/*.vsix; do
            is_vsix "$vsix" && printf '%s\n' "--install-extension" "$vsix"
        done
    done)

    if [ $# -eq 0 ]; then
        log "No VSIX to install"
        return 0
    fi

    # Already installed extensions are left as they are (no --force): a
    # newer version installed meanwhile is never downgraded.
    "$cli" "$@"
}

sync() {
    missing=""
    for id in $({ ids .devcontainer/devcontainer.json; ids .devcontainer.json; } | sort -u); do
        is_vsix "$PREFETCH_DIR/$(vsix_name "$id").vsix" || missing="$missing $id"
    done

    # shellcheck disable=SC2086 # one argument per extension id
    [ -n "$missing" ] && ! fetch "$CACHE_DIR" $missing && log "Some extensions could not be fetched"

    if [ -z "$(ls "$PREFETCH_DIR" "$CACHE_DIR" 2>/dev/null | grep '\.vsix$')" ]; then
        log "Nothing to provision"
        return 0
    fi

    log "Waiting for the VS Code server..."
    if ! cli=$(wait_cli); then
        log "No VS Code server showed up, giving up"
        return 1
    fi

    log "Installing extensions with $cli"
    install "$cli" "$PREFETCH_DIR" "$CACHE_DIR"
}

cmd="$1"
[ $# -gt 0 ] && shift
case "$cmd" in
fetch | ids | install | sync) "$cmd" "$@" ;;
*)
    sed -n '/^# Usage:/,/^$/s/^# \{0,1\}//p' "$0" >&2
    exit 1
    ;;
esac
