#!/bin/sh
export PATH=/usr/bin:$PATH

# Update root package.json/composer.json with GitVersion MajorMinorPatch
# Update workspace packages versions based on conventional commit scopes matching package names
# Minimal, jq and git required. Interactive prompts avoided.

set -e

# Parse arguments and display help if needed
eval $(
	zz_args "Sync versions in workspaces" $0 "$@" <<-help
		b before before Script to run in each workspace before version bump
        a after  after  Script to run in each workspace after version bump
        w -      write  Write changes to all files (default: only root package.json)
        - root   root   Root version to start from (default: from git tags or dotnet-gitversion)
	help
)


# Function to get root version from git tags or dotnet-gitversion
get_root_version() {
    if command -v dotnet-gitversion >/dev/null 2>&1; then
        zz_log i "Using dotnet-gitversion to get root version"
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

# function to bump version based on level (major, minor, patch)
get_bump_version() {
    ver=$1
    level=$2
    major=$(printf '%s' "${ver:-0}.0.0" | cut -d. -f1)
    minor=$(printf '%s' "${ver:-0}.0.0" | cut -d. -f2)
    patch=$(printf '%s' "${ver:-0}.0.0" | cut -d. -f3)

    case "$level" in
        major) major=$((major+1)); minor=0; patch=0;;
        minor) minor=$((minor+1)); patch=0;;
        patch) patch=$((patch+1));;
    esac
    
    zz_log - "Bumping $ver -> $major.$minor.$patch ($level)"

    echo "$major.$minor.$patch"
}

# function to get JSON file version using jq
get_file_version() {
    file=$1
    if [ -f "$file" ] && command -v jq >/dev/null 2>&1; then
        jq -r '.version // empty' "$file" 2>/dev/null || echo ""
    else
        echo ""
    fi
}   

# function to update JSON file version using jq
update_json_version() {
    file=$1
    newv=$2
    if [ -f "$file" ]; then
        if command -v jq >/dev/null 2>&1; then
            tmp=$(mktemp)
            jq --arg v "$newv" '.version = $v' "$file" > "$tmp" && mv "$tmp" "$file"
            zz_log s "Updated {U $file} to version $newv"
        else
            zz_log w "jq not available; cannot update $file"
        fi
    fi
}

# function to get level bump from commits for a given scope
get_scope_bump() {
    scope=$1
    esc="$(printf '%s' "$scope" | sed 's/[][\/.^$*]/\\&/g')"
    esc="\\(${esc}\\)"
    if printf '%s\n' "$commits" | grep -E "^feat${esc}:" >&2; then
        echo "minor"
    elif printf '%s\n' "$commits" | grep -E  "^fix${esc}:" >&2; then
        echo "patch"
    else
        echo ""
    fi
}

# function to get highest version between two versions
get_higher_version() {
    ver1=$1
    ver2=$2
    maj1=$(printf '%s' "${ver1:-0}.0.0" | cut -d. -f1)
    min1=$(printf '%s' "${ver1:-0}.0.0" | cut -d. -f2)
    pat1=$(printf '%s' "${ver1:-0}.0.0" | cut -d. -f3)
    maj2=$(printf '%s' "${ver2:-0}.0.0" | cut -d. -f1)
    min2=$(printf '%s' "${ver2:-0}.0.0" | cut -d. -f2)
    pat2=$(printf '%s' "${ver2:-0}.0.0" | cut -d. -f3)
    if [ "$maj1" -gt "$maj2" ] || { [ "$maj1" -eq "$maj2" ] && [ "$min1" -gt "$min2" ]; } || { [ "$maj1" -eq "$maj2" ] && [ "$min1" -eq "$min2" ] && [ "$pat1" -gt "$pat2" ]; }; then
        echo "$ver1"
    else
        echo "$ver2"
    fi
}

# Get root version whitout prefix
if [ -n "$root" ]; then
    root=$(printf '%s' "$root" | sed -E 's/.*[_v]?([0-9]+\.[0-9]+\.[0-9]+).*/\1/' | head -1)
    zz_log i "Using provided root version: $root"
else
    root=$(get_root_version)
    zz_log i "Determined root version: $root"
fi

# Determine commit range
last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [ -n "$last_tag" ]; then
    range="$last_tag..HEAD"
else
    range="HEAD"
fi

# Get commit messages in range
commits=$(git log --no-merges --pretty=format:%s $range 2>/dev/null || true)

# Read workspaces from root package.json
if [ -f package.json ] && command -v jq >/dev/null 2>&1; then

    ws=$(jq -r '.workspaces[]?' package.json 2>/dev/null || true)

    # Run before script if specified
    if [ -n "$before" ]; then
        zz_log i "Running <$before> script in each workspace"
        npm run --ws --if-present "$before"
    fi

    # For each workspace pattern, find directories and update their package.json versions
    for pattern in $ws; do
        for dir in $(ls -1d $pattern); do

            if [ -d "$dir" ]; then

                scope=$(basename "$dir")
                pfile="$dir/package.json"

                zz_log i "Processing workspace <$scope>"

                if [ -f "$pfile" ]; then
                          
                    level=$(get_scope_bump $scope)
     
                    if [ -n "$level" ]; then
                        
                        # if config sync-version is set, use that file instead of package.json
                        sv=$(jq -r '.config["sync-version"] // empty' "$pfile" 2>/dev/null || true)

                        # Get file to sync version from
                        if [ -n "$sv" ] && [ -f "$dir/$sv" ]; then
                            zz_log i "Sync from {U $dir/$sv}"
                            sfile="$dir/$sv"
                            cur=$(get_file_version "$sfile")
                        else
                            cur=$root
                        fi

                        new=$(get_bump_version "$cur" "$level")
                        update_json_version "$pfile" "$new"

                        # Update root version if cur is higher than root
                        root=$(get_higher_version "$root" "$new")
                        
                        # Write back to sync file if applicable
                        if [ -n "$write" ] && [ -n "$sv" ] && [ -f "$dir/$sv" ]; then
                            zz_log - "Sync to {U $dir/$sv}"
                            update_json_version "$sfile" "$new"
                        fi
                    else
                        zz_log - "No relevant commits found"
                    fi
                fi
            fi
        done
    done

    # Finally, update root package.json to highest version found and echo it
    if [ -n "$root" ]; then
        update_json_version "package.json" "$root"
        echo "$root"
    fi

    # Run after script if specified
    if [ -n "$after" ]; then
        zz_log i "Running <$after> script in each workspace"
        npm run --ws --if-present "$after"
    fi
fi

exit 0
