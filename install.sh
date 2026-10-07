#!/bin/sh

# Load the directory of the current script
source=$(dirname $(readlink -f $0))

### Bootstrap the shared zz-* core from https://github.com/tomgrv/scripts -
### the scripts formerly kept in src/common-utils/bin/ now live there,
### shared across every tomgrv repo. Idempotent: a zz-use already on PATH
### is reused as-is.
if ! command -v zz-use >/dev/null 2>&1; then
    _zz_setup_tmp=$(mktemp) || {
        echo "install.sh: mktemp failed" >&2
        exit 1
    }
    if ! curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" -o "$_zz_setup_tmp"; then
        echo "install.sh: failed to download the zz-use bootstrap" >&2
        rm -f "$_zz_setup_tmp"
        exit 1
    fi
    sh "$_zz_setup_tmp"
    _zz_setup_rc=$?
    rm -f "$_zz_setup_tmp"
    [ "$_zz_setup_rc" -eq 0 ] || exit "$_zz_setup_rc"
fi
export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"

zz-use zz-args zz-log jq resolve-context install-feature configure-feature

# Internal debug logging: quiet by default, enable with ZZ_LOG_DEBUG=1
_debug() { [ -n "${ZZ_LOG_DEBUG:-}" ] && zz-log - "$*" || true; }

eval $(
    zz-args "Manage devcontainer features" $0 "$@" <<-help
    - command   cmd     Command: init|list|deps|add|remove|update|help
    + target    target  Feature name(s), -a (all), -x (defaults), or empty to auto-detect
help
)

# --- feature discovery helpers ---

# Extract tomgrv devcontainer features listed in a devcontainer.json file
list_features() {
    _file="$1"
    [ -f "$_file" ] || return 0
    sed '/^\s*\/\//d' "$_file" | \
        jq -r '.features // {} | to_entries[] |
            select(.key | contains("tomgrv/devcontainer-features")) |
            .key | split("/")[-1] | split(":")[0]' 2>/dev/null
}

# Find devcontainer.json files in standard locations and extract features.
# Supports both the flat layout (.devcontainer/devcontainer.json) and the
# multi-config layout (.devcontainer/<name>/devcontainer.json).
find_features() {
    _search_dir="${1:-.}"
    _found=$(find "$_search_dir/.devcontainer" -maxdepth 2 -mindepth 1 -name "devcontainer.json" 2>/dev/null | head -1)
    if [ -n "$_found" ]; then
        list_features "$_found"
    fi
}

# All features available in src/ (excluding common-utils)
all_features() {
    find "$source/src" -mindepth 1 -maxdepth 1 -type d | while read _d; do
        _b=$(basename "$_d")
        [ "$_b" = "common-utils" ] || echo "$_b"
    done
}

# Default features from stubs devcontainer.json (-x)
default_features() {
    list_features "$source/stubs/.devcontainer/devcontainer.json"
}

# Resolve feature targets from a target argument:
#   -a  => all available features in src/
#   -x  => default features from stubs devcontainer.json
#   ""  => auto-detect from .devcontainer files in current dir
#   xxx => the named feature(s)
resolve_features() {
    case "${1:-}" in
        -a) all_features ;;
        -x) default_features ;;
        "") find_features "." ;;
        *)  echo "$@" | tr ' ' '\n' | grep -v '^$' ;;
    esac
}

# --- subcommands ---

# Count stub files (regular files + symlinks) under a feature's stubs directory
count_stubs() {
    _dir="$1"
    [ -d "$_dir" ] || { echo 0; return; }
    find "$_dir" \( -type f -o -type l \) 2>/dev/null | wc -l | tr -d ' '
}

cmd_help() {
    zz-log i "{BBlue devcontainer-features} - manage tomgrv devcontainer features"
    zz-log - ""
    zz-log - "{Yellow Usage:} npx tomgrv/devcontainer-features -- <command> <target...>"
    zz-log - ""
    zz-log - "{Yellow Commands:}"
    zz-log - "  init             Deploy root stubs into current repo"
    zz-log - "  list   <target>  List selected features"
    zz-log - "  deps   <target>  Show feature dependencies"
    zz-log - "  add    <target>  Install / deploy feature stubs"
    zz-log - "  remove <target>  Remove feature stubs"
    zz-log - "  update <target>  Reinstall features (-a re-detects all)"
    zz-log - "  help             Show this help"
    zz-log - ""
    zz-log - "{Yellow Targets:}"
    zz-log - "  <name>...  One or more feature names (e.g. githooks gitversion)"
    zz-log - "  -a         All features available in src/"
    zz-log - "  -x         Default features from stubs devcontainer.json"
    zz-log - "  (empty)    Auto-detect from .devcontainer/*/devcontainer.json"
    zz-log - ""
    zz-log - "{Yellow Examples:}"
    zz-log - "  npx tomgrv/devcontainer-features -- add -x"
    zz-log - "  npx tomgrv/devcontainer-features -- add githooks gitversion"
    zz-log - "  npx tomgrv/devcontainer-features -- list -a"
    zz-log - "  npx tomgrv/devcontainer-features -- deps gitversion"
    zz-log - ""
    zz-log - "Set {U ZZ_LOG_DEBUG=1} for verbose internal logs."
}

cmd_init() {
    zz-log i "Deploying $(count_stubs "$source/stubs") root stub(s)..."
    configure-feature -s "$source" .
    zz-log s "Root stubs deployed"
}

cmd_list() {
    _features=$(resolve_features $target)
    if [ -z "$_features" ]; then
        zz-log w "No features found"
        return 0
    fi
    echo "$_features" | tr ' ' '\n' | grep -v '^$'
}

cmd_deps() {
    _features=$(resolve_features $target)
    if [ -z "$_features" ]; then
        zz-log w "No features specified"
        return 0
    fi
    for _f in $(echo "$_features" | tr '\n' ' '); do
        [ -z "$_f" ] && continue
        zz-log i "Dependencies for $_f:"
        sh "$source/install-deps.sh" "$source" "$_f" | grep -v "^${_f}\$" | sed 's/^/  /'
    done
}

cmd_add() {
    if [ "${target:-}" = "-x" ]; then
        # Deploy root stubs then install each default feature
        sh "$source/install.sh" init
        sh "$source/install.sh" add $(default_features | tr '\n' ' ')
        return
    fi

    _features=$(resolve_features $target)
    if [ -z "$_features" ]; then
        if [ -z "${target:-}" ]; then
            zz-log w "No .devcontainer found to auto-detect features from"
            zz-log - "Specify feature names, {B -a} for all, or {B -x} for defaults (e.g. {B add -x})"
        else
            zz-log w "No features to add for target: $target"
        fi
        return 0
    fi

    zz-log i "Adding: $(echo $_features | tr '\n' ' ')"
    for _feature in $(echo "$_features" | tr '\n' ' '); do
        [ -z "$_feature" ] && continue
        # install-feat.sh logs "Deploying <feature>" itself, after checking
        # whether this feature was already handled earlier in the same
        # dependency tree (a shared/diamond dependency) — logging it here
        # unconditionally would print a "Deploying" line for features that
        # actually get skipped, making a normal install look like it loops.
        sh "$source/install-feat.sh" "$source" "$_feature"
    done
    zz-log s "Done adding features"
}

cmd_remove() {
    _features=$(resolve_features $target)
    if [ -z "$_features" ]; then
        zz-log w "No features specified"
        return 0
    fi

    for _feature in $(echo "$_features" | tr '\n' ' '); do
        [ -z "$_feature" ] && continue
        _stub_src="$source/src/$_feature/stubs"
        if [ ! -d "$_stub_src" ]; then
            zz-log w "No stubs found for $_feature"
            continue
        fi
        zz-log i "Removing {Purple $_feature} stubs ($(count_stubs "$_stub_src") tracked)..."
        find "$_stub_src" -type f | while read _stub; do
            _rel="${_stub#$_stub_src/}"
            _dest=$(echo "$_rel" | sed 's|^\.\./||;s|/\.\./|/|g')
            if [ -f "$_dest" ]; then
                zz-log - "Removing {U $_dest}..."
                rm -f "$_dest"
            fi
        done
        zz-log s "$_feature stubs removed"
    done
}

cmd_update() {
    if [ "${target:-}" = "-a" ]; then
        # Redeploy root stubs and reinstall all currently detected features
        sh "$source/install.sh" init
        _features=$(find_features "." | tr '\n' ' ')
    else
        _features=$(resolve_features $target)
    fi

    if [ -z "$_features" ]; then
        zz-log w "No features to update"
        return 0
    fi

    zz-log i "Updating: $(echo $_features | tr '\n' ' ')"
    for _feature in $(echo "$_features" | tr '\n' ' '); do
        [ -z "$_feature" ] && continue
        sh "$source/install.sh" add "$_feature"
    done
}

# --- dispatch ---
case "${cmd:-}" in
    init)   cmd_init ;;
    list)   cmd_list ;;
    deps)   cmd_deps ;;
    add)    cmd_add ;;
    remove) cmd_remove ;;
    update) cmd_update ;;
    help|-h|--help|"") cmd_help ;;
    *)
        zz-log e "Unknown command: $cmd"
        exit 1
        ;;
esac
