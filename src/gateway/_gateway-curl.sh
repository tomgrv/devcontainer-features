#!/bin/bash
# Gateway curl wrapper
#
# Transparently handles SSL inspection gateway interception forms (e.g. Zscaler):
# when a request is answered by the gateway redirect form instead of the real
# content, the wrapper auto-submits the form, saves the session cookies and
# replays the original request.
#
# Environment variables:
#   GATEWAY_COOKIE_FILE  Cookie jar path (default: ~/.gateway_cookies.txt)
#   GATEWAY_VERBOSE      Set to 1 to trace what the wrapper does (also: VERBOSE)
#   GATEWAY_MARKER       Pattern identifying the gateway form (default: gateway.zscaler)

COOKIE_FILE="${GATEWAY_COOKIE_FILE:-${HOME:-/tmp}/.gateway_cookies.txt}"
VERBOSE="${GATEWAY_VERBOSE:-${VERBOSE:-0}}"
MARKER="${GATEWAY_MARKER:-gateway.zscaler}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    [ "$VERBOSE" = "1" ] && echo -e "${GREEN}[gateway-curl]${NC} $*" >&2
    return 0
}

warn() {
    [ "$VERBOSE" = "1" ] && echo -e "${YELLOW}[gateway-curl]${NC} $*" >&2
    return 0
}

error() {
    echo -e "${RED}[gateway-curl]${NC} $*" >&2
}

# Locate the real curl binary, never this script itself
resolve_real_curl() {
    local self candidate
    self=$(readlink -f "${BASH_SOURCE[0]}")
    for candidate in /usr/bin/curl.real /usr/local/bin/curl.real; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    while IFS= read -r candidate; do
        [ "$(readlink -f "$candidate")" = "$self" ] && continue
        echo "$candidate"
        return 0
    done < <(type -aP curl)
    return 1
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [curl options] <URL>

Wrapper around curl that automatically handles SSL inspection gateway forms.
Detects redirects to gateway authentication forms, submits the form, saves
cookies, and retries the original request. All other requests are passed
through to the real curl unchanged.

Environment variables:
  GATEWAY_COOKIE_FILE  Path to cookie file (default: ~/.gateway_cookies.txt)
  GATEWAY_VERBOSE      Set to 1 to enable verbose wrapper output
  GATEWAY_MARKER       Pattern identifying the gateway form (default: gateway.zscaler)

Examples:
  $(basename "$0") https://example.com/file.tar.gz
  $(basename "$0") -H "Accept: application/json" https://example.com/api/data
EOF
}

# Percent-encode a string (jq if available, pure bash fallback)
urlencode() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq -sRr @uri
    else
        local s="$1" out="" c i hex
        for ((i = 0; i < ${#s}; i++)); do
            c="${s:$i:1}"
            case "$c" in
                [a-zA-Z0-9.~_-]) out+="$c" ;;
                *)
                    printf -v hex '%%%02X' "'$c"
                    out+="$hex"
                    ;;
            esac
        done
        printf '%s' "$out"
    fi
}

# Check if a response body is a gateway interception form
is_gateway_form() {
    grep -qF "$MARKER" "$1" 2>/dev/null && grep -q "_sm_ctn" "$1" 2>/dev/null
}

# Extract the value of a named form field
parse_form_field() {
    sed -n "s/.*name=[\"']$2[\"'][^>]*value=[\"']\([^\"']*\)[\"'].*/\1/p" "$1" | head -n1
}

# Extract the form action URL
get_form_action() {
    sed -n 's/.*<form[^>]*action="\(https:\/\/[^"]*\)".*/\1/p' "$1" | head -n1
}

# Submit the gateway form to obtain session cookies
submit_gateway_form() {
    local response_file="$1"
    local form_action sm_url sm_rid sm_cat query=""

    log "Gateway form detected, extracting fields..."

    form_action=$(get_form_action "$response_file")
    sm_url=$(parse_form_field "$response_file" "_sm_url")
    sm_rid=$(parse_form_field "$response_file" "_sm_rid")
    sm_cat=$(parse_form_field "$response_file" "_sm_cat")

    if [ -z "$form_action" ]; then
        error "Could not extract gateway form action URL"
        return 1
    fi

    [ -n "$sm_url" ] && query="${query}&_sm_url=$(urlencode "$sm_url")"
    [ -n "$sm_rid" ] && query="${query}&_sm_rid=$(urlencode "$sm_rid")"
    [ -n "$sm_cat" ] && query="${query}&_sm_cat=$(urlencode "$sm_cat")"
    query="${query#&}"

    log "Submitting gateway form to: ${form_action}?${query}"

    if "$CURL_CMD" -L -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0" \
        -o /dev/null \
        "${form_action}?${query}"; then
        log "Gateway form submitted, cookies saved to: $COOKIE_FILE"
        return 0
    fi

    error "Gateway form submission failed"
    return 1
}

main() {
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        if [ "$(basename "$0")" = "curl" ]; then
            exec "$CURL_CMD" "$@"
        fi
        usage
        exit 0
    fi

    # Scan arguments: find the URL, the requested output file, and any option
    # that makes body interception unsafe (in which case: pass through).
    local args=("$@") probe_args=()
    local url="" output_file="" passthrough=0 had_fail=0 url_count=0 has_ua=0
    local i=0 a cluster

    while [ $i -lt ${#args[@]} ]; do
        a="${args[$i]}"
        case "$a" in
            -o | --output)
                output_file="${args[$((i + 1))]}"
                i=$((i + 1))
                ;;
            -f | --fail)
                had_fail=1
                ;;
            -I | --head | -O | --remote-name | --remote-name-all | -J | \
                --remote-header-name | -T | --upload-file | -w | --write-out | \
                -K | --config | --output-dir | -Z | --parallel)
                passthrough=1
                probe_args+=("$a")
                ;;
            --url)
                url="${args[$((i + 1))]}"
                url_count=$((url_count + 1))
                i=$((i + 1))
                ;;
            http://* | https://*)
                [ -z "$url" ] && url="$a"
                url_count=$((url_count + 1))
                ;;
            --*)
                probe_args+=("$a")
                ;;
            -[a-zA-Z]*)
                cluster="${a#-}"
                if [[ "$cluster" =~ ^[sSfLkvigqnN46]*o?$ ]]; then
                    # Cluster of known boolean flags, optionally ending with -o <file>:
                    # strip -f (re-applied on delivery) and split a trailing -o.
                    if [[ "$cluster" == *f* ]]; then
                        had_fail=1
                        cluster="${cluster//f/}"
                    fi
                    if [[ "$cluster" == *o ]]; then
                        cluster="${cluster%o}"
                        output_file="${args[$((i + 1))]}"
                        i=$((i + 1))
                    fi
                    [ -n "$cluster" ] && probe_args+=("-$cluster")
                else
                    # Unknown cluster or option with attached value (e.g. -XPOST,
                    # -ofile): keep as-is, pass through if interception looks unsafe
                    [[ "$cluster" =~ [OIJTZw] ]] && passthrough=1
                    probe_args+=("$a")
                fi
                ;;
            *)
                probe_args+=("$a")
                ;;
        esac
        case "$a" in
            -H | --header)
                case "${args[$((i + 1))]}" in
                    [Uu]ser-[Aa]gent:*) has_ua=1 ;;
                esac
                ;;
            -A | --user-agent) has_ua=1 ;;
        esac
        i=$((i + 1))
    done

    # Requests we cannot safely intercept are passed through unchanged
    if [ "$passthrough" = "1" ] || [ -z "$url" ] || [ "$url_count" -gt 1 ]; then
        log "Passing request through to $CURL_CMD"
        exec "$CURL_CMD" "$@"
    fi

    local temp_file rc http_code
    temp_file=$(mktemp "${TMPDIR:-/tmp}/gateway-curl.XXXXXX") || exit 1
    trap 'rm -f "$temp_file"' EXIT

    # Probe request: capture the body so a gateway form can be detected
    local probe_extra=()
    [ "$has_ua" = "0" ] && probe_extra+=(-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0")

    log "Fetching: $url"
    http_code=$("$CURL_CMD" --location -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
        -o "$temp_file" -w '%{http_code}' \
        "${probe_extra[@]}" "${probe_args[@]}" "$url")
    rc=$?

    if [ $rc -eq 0 ] && is_gateway_form "$temp_file"; then
        log "Gateway interception detected, processing..."
        if submit_gateway_form "$temp_file"; then
            log "Replaying original request with session cookies..."
            "$CURL_CMD" -c "$COOKIE_FILE" -b "$COOKIE_FILE" "${args[@]}"
            exit $?
        fi
        error "Failed to process gateway redirect, returning original response"
    fi

    # No gateway involved: deliver the response as the real curl would have
    if [ "$had_fail" = "1" ] && [ "${http_code:-0}" -ge 400 ] 2>/dev/null; then
        error "The requested URL returned error: $http_code"
        exit 22
    fi

    if [ -n "$output_file" ] && [ "$output_file" != "-" ]; then
        mv "$temp_file" "$output_file"
        trap - EXIT
    else
        cat "$temp_file"
    fi
    exit $rc
}

CURL_CMD=$(resolve_real_curl)
if [ -z "$CURL_CMD" ]; then
    error "Could not find a real curl binary to wrap"
    exit 127
fi
log "Using real curl: $CURL_CMD"

main "$@"
