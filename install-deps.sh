#!/bin/sh

# Resolves transitive tomgrv/devcontainer-features dependencies from devcontainer-feature.json files.
# Usage: install-deps <source_dir> <feature> [<feature>...]
# Outputs the complete dependency list in topological order (deps before dependents), one per line.

_source="$1"
shift

if [ -z "$_source" ]; then
    echo "Usage: install-deps <source_dir> <feature>..." >&2
    exit 1
fi

features="$*"
[ -z "$features" ] && exit 0

# Extract direct tomgrv/devcontainer-features dependencies of a single feature
_feature_deps() {
    _manifest="$_source/src/$1/devcontainer-feature.json"
    [ -f "$_manifest" ] || return 0
    jq -r '.dependsOn // {} | to_entries[] |
        select(.key | contains("tomgrv/devcontainer-features")) |
        .key | split("/")[-1] | split(":")[0]' "$_manifest" 2>/dev/null
}

# BFS: collect the full set of reachable features (input + all transitive deps)
_all=""
_queue="$features"
while [ -n "$_queue" ]; do
    _next=""
    for _f in $_queue; do
        case " $_all " in
        *" $_f "*) continue ;;
        esac
        _all="$_all $_f"
        for _dep in $(_feature_deps "$_f"); do
            case " $_all $_next " in
            *" $_dep "*) ;;
            *) _next="$_next $_dep" ;;
            esac
        done
    done
    _queue="$_next"
done

# Topological sort: emit features whose tomgrv deps are all already emitted
_emitted=""
_pending="$_all"
_changed=1
while [ "$_changed" = "1" ] && [ -n "$_pending" ]; do
    _changed=0
    _still_pending=""
    for _f in $_pending; do
        _deps_ok=1
        for _dep in $(_feature_deps "$_f"); do
            case " $_emitted " in
            *" $_dep "*) ;;
            *)
                _deps_ok=0
                break
                ;;
            esac
        done
        if [ "$_deps_ok" = "1" ]; then
            _emitted="$_emitted $_f"
            _changed=1
        else
            _still_pending="$_still_pending $_f"
        fi
    done
    _pending="$_still_pending"
done

# Append any remaining features (handles cycles or missing manifests)
_emitted="$_emitted $_pending"

echo "$_emitted" | tr ' ' '\n' | grep -v '^$'
