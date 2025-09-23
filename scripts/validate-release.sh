#!/bin/bash
# Local validation script for multi-workspace release automation
# Usage: ./validate-release.sh [base-branch]

set -e

BASE_BRANCH="${1:-main}"
WORKSPACES=(act common-utils githooks gitutils gitversion larasets pecl)

echo "🔍 Multi-Workspace Release Validator"
echo "Comparing against: $BASE_BRANCH"
echo

# Function to get current version
get_current_version() {
    local workspace=$1
    jq -r '.version' "src/$workspace/devcontainer-feature.json" 2>/dev/null || echo "unknown"
}

# Function to analyze commits for workspace
analyze_commits() {
    local workspace=$1
    local commits=$(git log $BASE_REF..HEAD --oneline --grep="($workspace)" 2>/dev/null || echo "")
    
    if echo "$commits" | grep -q "BREAKING CHANGE\|($workspace)!"; then
        echo "major"
    elif echo "$commits" | grep -q "feat($workspace):"; then
        echo "minor"
    elif echo "$commits" | grep -q "fix($workspace):"; then
        echo "patch"
    else
        echo "none"
    fi
}

# Function to calculate next version
calculate_next_version() {
    local current_version=$1
    local bump_type=$2
    
    if [ "$bump_type" = "none" ]; then
        echo "$current_version"
        return
    fi
    
    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}
    
    case $bump_type in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "$major.$((minor + 1)).0" ;;
        patch) echo "$major.$minor.$((patch + 1))" ;;
    esac
}

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Check if base branch exists (try local first, then remote)
if git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    BASE_REF="$BASE_BRANCH"
elif git rev-parse --verify "origin/$BASE_BRANCH" >/dev/null 2>&1; then
    BASE_REF="origin/$BASE_BRANCH"
    echo "Using remote branch: origin/$BASE_BRANCH"
else
    echo "❌ Base branch '$BASE_BRANCH' not found (tried local and origin/$BASE_BRANCH)"
    exit 1
fi

CHANGES_FOUND=false

# Analyze each workspace
for workspace in "${WORKSPACES[@]}"; do
    # Check for file changes
    changed_files=$(git diff --name-only $BASE_REF..HEAD -- "src/$workspace/" 2>/dev/null || echo "")
    
    if [ -n "$changed_files" ]; then
        current_version=$(get_current_version "$workspace")
        bump_type=$(analyze_commits "$workspace")
        next_version=$(calculate_next_version "$current_version" "$bump_type")
        
        if [ "$current_version" != "$next_version" ]; then
            echo "📦 $workspace"
            echo "   Current: $current_version"
            echo "   Next:    $next_version ($bump_type)"
            echo "   Files:   $(echo $changed_files | wc -l) changed"
            echo
            CHANGES_FOUND=true
        else
            echo "⚠️  $workspace"
            echo "   Files changed but no conventional commits found"
            echo "   Add commits like: feat($workspace): description"
            echo
        fi
    fi
done

if [ "$CHANGES_FOUND" = true ]; then
    echo "✅ Ready for release! Run the GitHub workflow to create release branches."
else
    echo "ℹ️  No workspace changes detected or no valid conventional commits found."
    echo
    echo "💡 To create a release:"
    echo "   1. Make changes to workspace files in src/*/"
    echo "   2. Commit with conventional format: feat(workspace): description"
    echo "   3. Push changes and run the GitHub workflow"
fi

echo
echo "📖 Documentation: docs/MULTI_WORKSPACE_RELEASE.md"
echo "🚀 Quick Reference: docs/QUICK_REFERENCE.md"