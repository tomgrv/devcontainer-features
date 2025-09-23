#!/bin/sh
export PATH=/usr/bin:$PATH

# Update root package.json/composer.json with GitVersion MajorMinorPatch
# Update workspace packages versions based on conventional commit scopes matching package names
# Minimal, jq and git required. Interactive prompts avoided.

set -e

get_root_version() {
    if command -v dotnet-gitversion >/dev/null 2>&1; then
        v=$(dotnet-gitversion -config .gitversion -showvariable MajorMinorPatch 2>/dev/null || true)
        if [ -n "$v" ]; then
            echo "$v"
            return
        fi
    fi
    desc=$(git describe --tags --always --dirty 2>/dev/null || true)
    if [ -n "$desc" ]; then
        echo "$desc" | sed -E 's/.*[_v]?([0-9]+\.[0-9]+\.[0-9]+).*/\1/' | head -1
    else
        echo "1.0.0"
    fi
}

bump_version() {
    ver=$1
    level=$2
    IFS=. read -r major minor patch <<EOF
$ver
EOF
    major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}
    case "$level" in
        major) major=$((major+1)); minor=0; patch=0;;
        minor) minor=$((minor+1)); patch=0;;
        patch) patch=$((patch+1));;
    esac
    echo "$major.$minor.$patch"
}

update_json_version() {
    file=$1
    newv=$2
    if [ -f "$file" ]; then
        if command -v jq >/dev/null 2>&1; then
            tmp=$(mktemp)
            jq --arg v "$newv" '.version = $v' "$file" > "$tmp" && mv "$tmp" "$file"
            zz_log s "Updated $file to version $newv"
        else
            zz_log w "jq not available; cannot update $file"
        fi
    fi
}

ROOT_VER=$(get_root_version)
if [ -n "$ROOT_VER" ]; then
    update_json_version "package.json" "$ROOT_VER"
    update_json_version "composer.json" "$ROOT_VER"
fi

# Determine commit range
last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [ -n "$last_tag" ]; then
    range="$last_tag..HEAD"
else
    range="HEAD"
fi

commits=$(git log --no-merges --pretty=format:%s $range 2>/dev/null || true)

# Read workspaces from root package.json
if [ -f package.json ] && command -v jq >/dev/null 2>&1; then
    ws=$(jq -r '.workspaces[]?' package.json 2>/dev/null || true)
else
    ws="src/*"
fi

for pattern in $ws; do
    for dir in $pattern; do
        if [ -d "$dir" ]; then
            pkgjson="$dir/package.json"
            compjson="$dir/composer.json"
            if [ -f "$pkgjson" ]; then
                name=$(jq -r '.name // empty' "$pkgjson" 2>/dev/null || true)
                [ -z "$name" ] && name=$(basename "$dir")
                # Look for commits like feat(name): or fix(name):
                esc=$(printf '%s' "$name" | sed 's/[][^$.*/]/\\&/g')
                if printf "%s" "$commits" | grep -E "^feat\(([^)]*${esc}[^)]*)\):" >/dev/null 2>&1; then
                    level=minor
                elif printf "%s" "$commits" | grep -E "^fix\(([^)]*${esc}[^)]*)\):" >/dev/null 2>&1; then
                    level=patch
                else
                    level=""
                fi
                if [ -n "$level" ]; then
                    cur=$(jq -r '.version // "0.0.0"' "$pkgjson" 2>/dev/null || echo "0.0.0")
                    newv=$(bump_version "$cur" "$level")
                    update_json_version "$pkgjson" "$newv"
                    [ -f "$compjson" ] && update_json_version "$compjson" "$newv"
                else
                    zz_log i "No relevant commits for $name"
                fi
            fi
        fi
    done
done

zz_log s "sync-versions finished"
exit 0
