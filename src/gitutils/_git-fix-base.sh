#!/bin/sh

# Function to print help and manage arguments
eval $(
	zz_args "Fix git base - rebase commits from one branch to another" $0 "$@" <<-help
		    p -      push     force push changes to remote
		    d -      dryrun   show what would be done without making changes
		    - target target    target branch to rebase commits onto
		    - source source    source branch to take commits from (default: current branch)
	help
)

# Validate required arguments
if [ -z "$target" ]; then
	zz_log e 'Target branch is required. Use -h for help.'
	exit 1
fi

# Get current branch if source is not specified
if [ -z "$source" ]; then
	source=$(git rev-parse --abbrev-ref HEAD)
	zz_log i "Using current branch as source: $source"
fi

# Validate that source and target are different
if [ "$source" = "$target" ]; then
	zz_log e "Source and target branches cannot be the same: $source"
	exit 1
fi

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

# Validate branches exist
if ! git rev-parse --verify "$source" >/dev/null 2>&1; then
	zz_log e "Source branch '$source' does not exist"
	exit 1
fi

if ! git rev-parse --verify "$target" >/dev/null 2>&1; then
	zz_log e "Target branch '$target' does not exist"
	exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
	zz_log e 'Working directory is not clean. Please commit or stash your changes.'
	exit 1
fi

# Find the merge base between source and target
merge_base=$(git merge-base "$source" "$target")
if [ -z "$merge_base" ]; then
	zz_log e "Could not find common ancestor between '$source' and '$target'"
	exit 1
fi

# Get commits that are in source but not in target
commits_to_move=$(git log --reverse --pretty=oneline  --all --ancestry-path "$target".."$source" | grep -vE "^[a-f0-9]+ Merge" | awk '{print $1}')

if [ -z "$commits_to_move" ]; then
	zz_log i "No commits to move from '$source' to '$target'"
	exit 0
fi

# Count commits
commit_count=$(echo "$commits_to_move" | wc -l)
zz_log i "Found $commit_count commit(s) to move from '$source' to '$target'"

# Show commits in dry-run mode
if [ -n "$dryrun" ]; then
	zz_log i "Commits that would be moved:"
	echo "$commits_to_move" | while read commit; do
		if [ -n "$commit" ]; then
			echo "  $(git log --oneline -1 "$commit")"
		fi
	done
	zz_log i "To execute, run without -n flag"
	exit 0
fi

# Confirm the operation
zz_log i "About to move $commit_count commit(s) from '$source' to '$target':"
echo "$commits_to_move" | while read commit; do
	if [ -n "$commit" ]; then
		zz_log - "  $(git log --oneline -1 "$commit")" >&2
	fi
done
zz_log i "This will:"
zz_log -  "1. Checkout '$target' branch"
zz_log -  "2. Create a temporary branch for the rebase"
zz_log -  "3. Cherry-pick commits from '$source'"
zz_log -  "4. Reset '$source' to the merge base"
zz_log -  "5. Fast-forward '$target' to include the rebased commits"
echo ""
if ! zz_ask "Yn" "Continue?"; then
	zz_log e "Operation cancelled"
	exit 1
fi

# Store current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Create a temporary branch name
temp_branch="temp-fix-base-$(date +%s)"

# Checkout target branch
zz_log i "Checking out '$target' branch"
if ! git checkout "$target"; then
	zz_log e "Failed to checkout '$target' branch"
	exit 1
fi

# Create temporary branch from target
zz_log i "Creating temporary branch '$temp_branch'"
if ! git checkout -b "$temp_branch"; then
	zz_log e "Failed to create temporary branch"
	git checkout "$current_branch"
	exit 1
fi

# Cherry-pick commits from source
zz_log i "Cherry-picking commits..."
failed=0
echo "$commits_to_move" | while read commit; do
	if [ -n "$commit" ]; then
		if ! git cherry-pick "$commit" --strategy=recursive -X theirs --allow-empty; then
			zz_log e "Cherry-pick failed on commit $commit"
			failed=1
			break
		fi
	fi
done

# Check if cherry-pick succeeded
if [ $failed -eq 1 ]; then
	zz_log e "Please resolve conflicts and run 'git cherry-pick --continue'"
	zz_log e "Or run 'git cherry-pick --abort' to cancel"
	exit 1
fi

# Reset source branch to merge base
zz_log i "Resetting '$source' to merge base"
if ! git checkout "$source"; then
	zz_log e "Failed to checkout '$source' branch"
	# Cleanup temp branch
	git branch -D "$temp_branch" 2>/dev/null
	exit 1
fi

if ! git reset --hard "$merge_base"; then
	zz_log e "Failed to reset '$source' branch"
	exit 1
fi

# Fast-forward target branch
zz_log i "Fast-forwarding '$target' branch"
if ! git checkout "$target"; then
	zz_log e "Failed to checkout '$target' branch"
	exit 1
fi

if ! git merge --ff-only "$temp_branch"; then
	zz_log e "Failed to fast-forward '$target' branch"
	# Cleanup temp branch
	git branch -D "$temp_branch" 2>/dev/null
	exit 1
fi

# Cleanup temporary branch
zz_log i "Cleaning up temporary branch"
git branch -D "$temp_branch"

# Return to original branch if it still exists and is different from source
if [ "$current_branch" != "$source" ] && git rev-parse --verify "$current_branch" >/dev/null 2>&1; then
	git checkout "$current_branch"
else
	# If original branch was source, stay on target
	zz_log i "Staying on '$target' branch"
fi

# Push changes if force flag is set
if [ -n "$force" ]; then
	zz_log i "Pushing changes to remote..."
	
	# Push source branch (reset)
	if git rev-parse --verify "origin/$source" >/dev/null 2>&1; then
		zz_log i "Force pushing '$source' branch"
		git push --force-with-lease origin "$source"
	fi
	
	# Push target branch (with new commits)
	if git rev-parse --verify "origin/$target" >/dev/null 2>&1; then
		zz_log i "Pushing '$target' branch"
		git push origin "$target"
	fi
fi

zz_log i "Successfully moved commits from '$source' to '$target'"