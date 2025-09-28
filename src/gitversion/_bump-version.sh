#!/bin/sh

# Bump version utility - updates version numbers in files based on configuration
# Used by bump-changelog and other versioning scripts
#
# This script reads configuration from package.json commit-and-tag-version.bumpFiles
# and updates version numbers in specified files with workspace-aware functionality.

set -e

# Parse command line arguments using zz_args helper
eval $(
    zz_args "Bump version files utility" $0 "$@" <<- help
        -   version   version     Version to set in files (optional - will auto-determine if not provided)
        m   minimal   minimal     Only bump workspace files if commit scope relates to workspace name
        r   range     range       Git range to check for affected workspaces (required for minimal mode)
        d   -         dry_run     Show what would be updated without making changes
help
)

# Change to repository root to ensure we're working from the correct directory
cd "$(git rev-parse --show-toplevel)" > /dev/null

# ===== WORKSPACE MANAGEMENT FUNCTIONS =====

# Get workspace directories from package.json workspaces configuration
# Returns list of workspace directories, falls back to all subdirectories if no workspaces config
get_workspace_dirs() {
    if [ -f "package.json" ] && command -v jq > /dev/null 2>&1; then
        # Try to get workspaces array from package.json
        local workspaces=$(jq -r '.workspaces[]? // empty' package.json 2> /dev/null)

        if [ -n "$workspaces" ]; then
            # Use configured workspaces
            echo "$workspaces" | while read -r workspace_pattern; do
                # Handle glob patterns by expanding them
                if echo "$workspace_pattern" | grep -q '\*'; then
                    # Use find to expand glob patterns like "packages/*"
                    find . -path "./$workspace_pattern" -type d -mindepth 1 -maxdepth 2 2> /dev/null || true
                else
                    # Direct path
                    if [ -d "$workspace_pattern" ]; then
                        echo "$workspace_pattern"
                    fi
                fi
            done
        else
            # Fallback to all subdirectories
            find . -type d -mindepth 1 -maxdepth 1
        fi
    else
        # Fallback to all subdirectories when package.json or jq not available
        find . -type d -mindepth 1 -maxdepth 1
    fi
}

# Get affected workspace names from commit history for a given range
# Parameters: range (git range specification)
# Returns list of workspace names that have commits with matching scopes
get_affected_workspaces() {
    local range="$1"

    # Extract scopes from commits and match against workspace names
    git log --oneline --format="%s" "$range" 2> /dev/null \
        | sed -n 's/^[^(]*(\([^)]*\)):.*/\1/p' \
        | sort -u \
        | while read -r commit_scope; do
            # Check if this scope matches any workspace directory
            get_workspace_dirs | while read -r workspace_dir; do
                local workspace_name=$(basename "$workspace_dir")
                if [ "$commit_scope" = "$workspace_name" ]; then
                    echo "$workspace_dir"
                fi
            done
        done | sort -u
}

# ===== VERSION DETERMINATION FUNCTIONS =====

# Get all git tags in reverse chronological order (newest first)
# Filters to semantic version tags and includes the initial commit
get_all_tags() {
    # Get semantic version tags sorted by version number
    git tag -l --sort=-version:refname | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' || echo ""
    # Include the initial commit as a reference point
    git rev-list --max-parents=0 HEAD
}

# Get the latest semantic version tag from git history
# Returns the most recent tag that matches semantic versioning pattern
get_latest_tag() {
    get_all_tags | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# Calculate the git range from HEAD to the latest tag
# Returns a git range specification for use throughout the script
get_latest_range() {
    local latest_tag=$(get_latest_tag)
    echo "HEAD" "$latest_tag" | list_changelog_range
}

# Determine git commit range from current and previous references
# Parameters:
#   current_ref: Git ref to generate changelog up to (default: HEAD)
#   previous_ref: Git ref to start from (if empty, starts from repo origin)
# Output: Git range specification (e.g., "v1.0.0..HEAD", "abc123..def456")
list_changelog_range() {
    read -r current_ref previous_ref

    # Determine commit range - either between two refs or from repo origin
    if [ -n "$previous_ref" ]; then
        echo "${previous_ref}..${current_ref}"
    else
        # From repo origin (initial commit) to current ref
        local initial_commit=$(git rev-list --max-parents=0 HEAD 2> /dev/null | head -1)
        if [ -n "$initial_commit" ]; then
            echo "${initial_commit}..${current_ref}"
        else
            # Fallback to all commits if can't find initial commit
            echo "$current_ref"
        fi
    fi
}

# Automatically determine the next version based on git history and conventional commits
# Parameters: range (git range specification)
# Analyzes commits since the last tag to determine version bump (patch, minor, major)
# Handles full semver format including pre-release and build metadata
# Returns the next semantic version number
auto_determine_version() {
    local range="$1"

    # Get the latest version tag, filtering out non-semantic versions
    local latest_tag=$(get_latest_tag)

    # If no version tags exist, start with 0.1.0
    if [ -z "$latest_tag" ]; then
        echo "0.1.0"
        return
    fi

    # Extract version numbers from tag (remove 'v' prefix if present)
    local version_num=$(echo "$latest_tag" | sed 's/^v//')
    
    # Handle full semver format by extracting only the core version (major.minor.patch)
    # This handles cases like "1.2.3-alpha.1" or "1.2.3+build.1"
    local core_version=$(echo "$version_num" | sed 's/[-+].*//')
    local major=$(echo "$core_version" | cut -d. -f1)
    local minor=$(echo "$core_version" | cut -d. -f2)
    local patch=$(echo "$core_version" | cut -d. -f3)

    # Analyze commits using the provided range to determine bump type
    local bump_type=$(git log --oneline --format="%s" "$range" 2> /dev/null \
        | while read -r commit_msg; do
            # Check for breaking changes
            if echo "$commit_msg" | grep -q "!:" || git log --oneline --format="%B" "$range" | grep -q "BREAKING CHANGE:"; then
                echo "major"
                break
            fi
            # Check for features
            if echo "$commit_msg" | grep -q "^feat[^:]*:"; then
                echo "minor"
            fi
            # Check for fixes
            if echo "$commit_msg" | grep -q "^fix[^:]*:"; then
                echo "patch"
            fi
        done | head -1)

    # Calculate new version based on bump type
    case "$bump_type" in
        "major") echo "$((major + 1)).0.0" ;;
        "minor") echo "${major}.$((minor + 1)).0" ;;
        "patch") echo "${major}.${minor}.$((patch + 1))" ;;
        *) echo "$core_version" ;;  # No changes detected, keep the same core version
    esac
}

# Format version string to ensure proper semantic versioning
# Parameters: version (raw version string from user input)
# Returns formatted version string with appropriate prefix
format_version() {
    local raw_version="$1"

    if [ -z "$raw_version" ]; then
        zz_log e "Version cannot be empty"
        return 1
    fi

    # Get configured version prefix from git config or default to "v"
    local prefix=$(git config gitflow.prefix.versiontag || echo "v")

    # Remove any existing prefix for processing
    local clean_version=$(echo "$raw_version" | sed "s/^${prefix}//")

    # Complete partial versions (e.g., "5.26" -> "5.26.0", "5" -> "5.0.0")
    case "$clean_version" in
        [0-9]*.[0-9]*.[0-9]*)
            # Already complete semantic version
            ;;
        [0-9]*.[0-9]*)
            # Major.minor: add patch
            clean_version="${clean_version}.0"
            ;;
        [0-9]*)
            # Major only: add minor.patch
            clean_version="${clean_version}.0.0"
            ;;
        *)
            zz_log e "Invalid version format: $raw_version"
            return 1
            ;;
    esac

    # Apply prefix if user provided it or if existing tags use it
    if echo "$raw_version" | grep -q "^${prefix}" || git tag -l | grep -qE "^${prefix}[0-9]" || [ -z "$(git tag -l)" ]; then
        echo "${prefix}${clean_version}"
    else
        echo "$clean_version"
    fi
}

# ===== VERSION FILE UPDATE FUNCTIONS =====

# Trim version prefix for file storage
# Parameters: version
# Returns version without prefix (e.g., "v1.2.3" -> "1.2.3")
trim_version_prefix() {
    local version="$1"
    local prefix=$(git config gitflow.prefix.versiontag || echo "v")
    echo "$version" | sed "s/^${prefix}//"
}

# Update version in a JSON file using jq
# Parameters: filepath, version
update_json_file() {
    local filepath="$1"
    local version="$2"

    if [ -n "$dry_run" ]; then
        zz_log i "Would update JSON file: $filepath to version $version"
        return 0
    fi

    if command -v jq > /dev/null 2>&1; then
        jq --arg version "$version" '.version = $version' "$filepath" > "${filepath}.tmp" && mv "${filepath}.tmp" "$filepath"
        git add "$filepath"
        return 0
    else
        zz_log e "jq not available for updating JSON file: $filepath"
        return 1
    fi
}

# Update version in a plain text file
# Parameters: filepath, version
update_text_file() {
    local filepath="$1"
    local version="$2"

    if [ -n "$dry_run" ]; then
        zz_log i "Would update text file: $filepath to version $version"
        return 0
    fi

    echo "$version" > "$filepath"
    git add "$filepath"
}

# Helper function to update files with workspace logic
# Parameters: range, filename, version, is_workspace, update_function
update_files() {
    local range="$1"
    local filename="$2"
    local version="$3"
    local is_workspace="$4"
    local update_function="$5"

    if [ "$is_workspace" = true ]; then
        if [ -n "$filename" ]; then
            # Determine which workspaces to update based on minimal flag
            local workspace_list
            if [ -n "$minimal" ]; then
                if [ -z "$range" ]; then
                    zz_log e "Range parameter required for minimal mode"
                    return 1
                fi
                zz_log i "Minimal mode: only bumping workspaces with related commits"
                workspace_list=$(get_affected_workspaces "$range")

                if [ -z "$workspace_list" ]; then
                    zz_log w "No workspaces affected by recent commits - skipping workspace updates"
                    return
                fi
            else
                workspace_list=$(get_workspace_dirs)
            fi

            zz_log i "Bumping version in $filename across workspaces to $version"
            echo "$workspace_list" | while read -r workspace_dir; do
                local workspace_file="$workspace_dir/$filename"
                if [ -f "$workspace_file" ]; then
                    zz_log - "Updating $workspace_file"
                    "$update_function" "$workspace_file" "$version"
                fi
            done
        else
            zz_log w "No filename specified for workspace bump"
        fi
    else
        if [ -n "$filename" ] && [ -f "$filename" ]; then
            zz_log i "Bumping version in $filename to $version"
            "$update_function" "$filename" "$version"
        else
            zz_log w "Bump file not found: $filename"
        fi
    fi
}

# ===== MAIN BUMP FUNCTION =====

# Bump version files based on commit-and-tag-version.bumpFiles configuration in package.json
# Parameters: version, range (optional, required for minimal mode)
# Updates version numbers in specified files according to their configured patterns
bump_version_files() {
    local version="$1"
    local range="$2"

    # Check if package.json exists and jq is available
    if [ ! -f "package.json" ] || ! command -v jq > /dev/null 2>&1; then
        zz_log w "package.json not found or jq not available - skipping version file bumping"
        return
    fi

    # Get bumpFiles configuration from package.json
    local bump_files=$(jq -r '."commit-and-tag-version".bumpFiles[]? | @json' package.json 2> /dev/null)

    if [ -z "$bump_files" ]; then
        zz_log w "No bumpFiles configuration found in package.json"
        return
    fi

    # Process each bump file configuration
    echo "$bump_files" | while read -r bump_file_json; do
        if [ -n "$bump_file_json" ] && [ "$bump_file_json" != "null" ]; then
            # Parse the bump file configuration
            local filename=$(echo "$bump_file_json" | jq -r '.filename // empty')
            local type=$(echo "$bump_file_json" | jq -r '.type // "json"')

            # Check if this is a workspace operation (type starts with @ws)
            local is_workspace=false
            local actual_type="$type"

            if echo "$type" | grep -q '@ws$'; then
                is_workspace=true
                actual_type=$(echo "$type" | sed 's/@ws$//')
                if [ -z "$actual_type" ]; then
                    zz_log w "Invalid @ws type format: $type"
                    continue
                fi
            fi

            case "$actual_type" in
                "json")
                    update_files "$range" "$filename" "$version" "$is_workspace" "update_json_file"
                    ;;
                "plain-text")
                    update_files "$range" "$filename" "$version" "$is_workspace" "update_text_file"
                    ;;
                *)
                    zz_log w "Unsupported bump file type: $type for $filename"
                    ;;
            esac
        fi
    done

    zz_log s "Version files updated to $version"
}

# ===== MAIN EXECUTION LOGIC =====

# Calculate git range for version determination
range=$(get_latest_range)

# Auto-determine version if not specified, otherwise format the provided version
if [ -z "$version" ]; then
    version=$(auto_determine_version "$range")
    zz_log s "Auto-determined version: $version"
fi

# Format and validate the provided version
version=$(format_version "$version")
if [ $? -eq 0 ]; then
    zz_log s "Using formatted version: $version"
else
    zz_log e "Failed to format version: $version"
    exit 1
fi

# Always output the version & range to stdout (so it can be captured by other scripts)
echo "$range $version"

# If this is a dry run, exit after outputting the version
if [ -n "$dry_run" ]; then
    exit 0
fi

# Check if minimal mode requires range parameter
if [ -n "$minimal" ] && [ -z "$range" ]; then
    zz_log e "Range parameter is required when using minimal mode" >&2
    exit 1
fi

# Trim version prefix for file storage (package.json expects numeric version)
clean_version=$(trim_version_prefix "$version")

# Execute version file bumping
bump_version_files "$clean_version" "$range"
