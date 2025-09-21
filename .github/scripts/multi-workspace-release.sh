#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in dry run mode
DRY_RUN=${DRY_RUN:-false}

if [ "$DRY_RUN" = "true" ]; then
    log_warning "Running in DRY RUN mode - no actual changes will be made"
fi

# Ensure we're on main branch
log_info "Ensuring we're on main branch..."
if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
    git pull origin main
elif git show-ref --verify --quiet refs/remotes/origin/main; then
    git checkout -b main origin/main
else
    log_error "Main branch not found. Please ensure you're working on a repository with a main branch."
    exit 1
fi

# Get current commit hash for reference
CURRENT_COMMIT=$(git rev-parse HEAD)
log_info "Current commit: $CURRENT_COMMIT"

# Initialize GitFlow if not already done
if [ ! -f .git/config ] || ! git config --get gitflow.branch.master > /dev/null 2>&1; then
    log_info "Initializing git-flow..."
    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY RUN: Would initialize git-flow"
    else
        # Create develop branch if it doesn't exist
        if ! git show-ref --verify --quiet refs/heads/develop; then
            git checkout -b develop main
            git push origin develop
            git checkout main
        fi
        git flow init -d
    fi
fi

# Define workspace directories
WORKSPACES=(
    "src/act"
    "src/common-utils" 
    "src/githooks"
    "src/gitutils"
    "src/gitversion"
    "src/larasets"
    "src/pecl"
)

# Function to get the last release tag for a workspace
get_last_release_tag() {
    local workspace=$1
    # Look for tags that match the workspace pattern
    git tag --sort=-version:refname | grep -E "^${workspace##*/}-[0-9]" | head -n1 || echo ""
}

# Function to get conventional commit type
get_commit_type() {
    local commit_msg="$1"
    if echo "$commit_msg" | grep -qE "^(feat|feature)(\([^)]*\))?!?:"; then
        echo "minor"
    elif echo "$commit_msg" | grep -qE "^(fix|bug)(\([^)]*\))?!?:"; then
        echo "patch"
    elif echo "$commit_msg" | grep -qE "BREAKING CHANGE|!:"; then
        echo "major"
    elif echo "$commit_msg" | grep -qE "^(chore|docs|style|refactor|perf|test|ci|build)(\([^)]*\))?!?:"; then
        echo "patch"
    else
        echo "none"
    fi
}

# Function to analyze workspace changes and determine version bump
analyze_workspace_changes() {
    local workspace=$1
    local workspace_name="${workspace##*/}"
    
    log_info "Analyzing changes for workspace: $workspace_name" >&2
    
    # Get the last release tag for this workspace
    local last_tag=$(get_last_release_tag "$workspace")
    local since_ref="main"
    
    if [ -n "$last_tag" ]; then
        since_ref="$last_tag"
        log_info "Last release tag for $workspace_name: $last_tag" >&2
    else
        log_info "No previous release tag found for $workspace_name, analyzing all commits" >&2
    fi
    
    # Get commits that affect this workspace since last release
    local commits=$(git log --oneline --pretty=format:"%s" "$since_ref..HEAD" -- "$workspace" 2>/dev/null || echo "")
    
    if [ -z "$commits" ]; then
        log_info "No changes detected for workspace: $workspace_name" >&2
        echo "none"
        return
    fi
    
    log_info "Commits affecting $workspace_name:" >&2
    echo "$commits" | while read -r commit; do
        if [ -n "$commit" ]; then
            log_info "  - $commit" >&2
        fi
    done
    
    # Analyze commit types to determine version bump
    local max_bump="none"
    
    while IFS= read -r commit; do
        if [ -n "$commit" ]; then
            local bump_type=$(get_commit_type "$commit")
            case "$bump_type" in
                "major")
                    max_bump="major"
                    break
                    ;;
                "minor")
                    if [ "$max_bump" != "major" ]; then
                        max_bump="minor"
                    fi
                    ;;
                "patch")
                    if [ "$max_bump" = "none" ]; then
                        max_bump="patch"
                    fi
                    ;;
            esac
        fi
    done <<< "$commits"
    
    log_info "Determined version bump for $workspace_name: $max_bump" >&2
    echo "$max_bump"
}

# Function to calculate new version
calculate_new_version() {
    local current_version=$1
    local bump_type=$2
    
    if [ "$bump_type" = "none" ]; then
        echo "$current_version"
        return
    fi
    
    # Parse version components
    local major=$(echo "$current_version" | cut -d. -f1)
    local minor=$(echo "$current_version" | cut -d. -f2)
    local patch=$(echo "$current_version" | cut -d. -f3)
    
    case "$bump_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to update workspace version
update_workspace_version() {
    local workspace=$1
    local new_version=$2
    local feature_file="$workspace/devcontainer-feature.json"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY RUN: Would update $feature_file to version $new_version"
        return
    fi
    
    log_info "Updating $feature_file to version $new_version"
    
    # Use jq to update the version field
    local temp_file=$(mktemp)
    jq --arg new_version "$new_version" '.version = $new_version' "$feature_file" > "$temp_file"
    mv "$temp_file" "$feature_file"
    
    # Stage the file
    git add "$feature_file"
}

# Main execution
log_info "Starting multi-workspace release process..."

# Arrays to track updates
declare -a UPDATED_WORKSPACES=()
declare -a VERSION_UPDATES=()

# Analyze each workspace
for workspace in "${WORKSPACES[@]}"; do
    workspace_name="${workspace##*/}"
    feature_file="$workspace/devcontainer-feature.json"
    
    if [ ! -f "$feature_file" ]; then
        log_warning "No devcontainer-feature.json found in $workspace, skipping..."
        continue
    fi
    
    # Get current version
    current_version=$(jq -r '.version' "$feature_file")
    log_info "Current version for $workspace_name: $current_version"
    
    # Analyze changes
    bump_type=$(analyze_workspace_changes "$workspace")
    
    if [ "$bump_type" = "none" ]; then
        log_info "No version update needed for $workspace_name"
        continue
    fi
    
    # Calculate new version
    new_version=$(calculate_new_version "$current_version" "$bump_type")
    
    log_success "Version update for $workspace_name: $current_version -> $new_version ($bump_type)"
    
    UPDATED_WORKSPACES+=("$workspace_name")
    VERSION_UPDATES+=("- **$workspace_name**: $current_version → $new_version ($bump_type)")
done

# Check if we have any updates
if [ ${#UPDATED_WORKSPACES[@]} -eq 0 ]; then
    log_info "No workspaces require version updates. Exiting."
    exit 0
fi

# Generate release version based on the highest version change
log_info "Workspaces to update: ${UPDATED_WORKSPACES[*]}"

# Calculate overall release version using GitVersion
if command -v dotnet >/dev/null 2>&1 && dotnet tool list -g | grep -q gitversion; then
    BASE_VERSION=$(dotnet gitversion -showvariable MajorMinorPatch 2>/dev/null || echo "")
    if [ -z "$BASE_VERSION" ] || [[ "$BASE_VERSION" == *"ERROR"* ]] || [[ "$BASE_VERSION" == *"INFO"* ]]; then
        log_warning "GitVersion failed, falling back to version calculation"
        # Get the latest tag or use default version
        BASE_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "1.0.0")
        # Increment patch version for fallback
        major=$(echo "$BASE_VERSION" | cut -d. -f1)
        minor=$(echo "$BASE_VERSION" | cut -d. -f2) 
        patch=$(echo "$BASE_VERSION" | cut -d. -f3)
        patch=$((patch + 1))
        BASE_VERSION="$major.$minor.$patch"
    fi
else
    log_warning "GitVersion not available, using fallback version calculation"
    # Get the latest tag or use default version
    BASE_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "1.0.0")
    # Increment patch version for fallback
    major=$(echo "$BASE_VERSION" | cut -d. -f1)
    minor=$(echo "$BASE_VERSION" | cut -d. -f2) 
    patch=$(echo "$BASE_VERSION" | cut -d. -f3)
    patch=$((patch + 1))
    BASE_VERSION="$major.$minor.$patch"
fi
RELEASE_VERSION="$BASE_VERSION"

log_info "Base version from GitVersion: $BASE_VERSION"
log_info "Release version: $RELEASE_VERSION"

# Create release branch (gitflow style)
RELEASE_BRANCH="release/$RELEASE_VERSION"

if [ "$DRY_RUN" = "true" ]; then
    log_info "DRY RUN: Would create release branch: $RELEASE_BRANCH"
else
    log_info "Creating release branch: $RELEASE_BRANCH"
    
    # Check if release branch already exists
    if git show-ref --verify --quiet "refs/heads/$RELEASE_BRANCH"; then
        log_error "Release branch $RELEASE_BRANCH already exists!"
        exit 1
    fi
    
    # Create release branch using git-flow
    git flow release start "$RELEASE_VERSION"
    
    # Update versions for affected workspaces
    for workspace in "${WORKSPACES[@]}"; do
        workspace_name="${workspace##*/}"
        feature_file="$workspace/devcontainer-feature.json"
        
        if [ ! -f "$feature_file" ]; then
            continue
        fi
        
        # Check if this workspace is in our update list
        if [[ " ${UPDATED_WORKSPACES[*]} " =~ " ${workspace_name} " ]]; then
            current_version=$(jq -r '.version' "$feature_file")
            bump_type=$(analyze_workspace_changes "$workspace")
            new_version=$(calculate_new_version "$current_version" "$bump_type")
            
            update_workspace_version "$workspace" "$new_version"
        fi
    done
    
    # Commit the version updates
    if git diff --cached --quiet; then
        log_warning "No staged changes to commit"
    else
        log_info "Committing version updates..."
        git commit -m "chore: bump versions for release $RELEASE_VERSION

Updated workspaces:
$(printf '%s\n' "${VERSION_UPDATES[@]}")

Automated release via multi-workspace release workflow"
    fi
    
    # Push the release branch
    log_info "Pushing release branch..."
    git push origin "$RELEASE_BRANCH"
fi

# Set outputs for GitHub Actions
echo "release_branch=$RELEASE_BRANCH" >> $GITHUB_OUTPUT
echo "release_version=$RELEASE_VERSION" >> $GITHUB_OUTPUT
echo "base_version=$BASE_VERSION" >> $GITHUB_OUTPUT

# Format updated workspaces for PR description
UPDATED_WORKSPACES_TEXT=$(printf '%s\n' "${VERSION_UPDATES[@]}")
echo "updated_workspaces<<EOF" >> $GITHUB_OUTPUT
echo "$UPDATED_WORKSPACES_TEXT" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT

log_success "Multi-workspace release process completed!"
log_success "Release branch: $RELEASE_BRANCH"
log_success "Updated workspaces: ${UPDATED_WORKSPACES[*]}"