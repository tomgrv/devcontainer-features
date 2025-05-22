#!/bin/sh

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
	zz_args "Fix privacy in history" $0 "$@" <<-help
		p -      push      push to remote
		e -      edit      edit commit message
		- sha    sha       sha commit to start from
	help
)

# Prepare environment variables GIT_EDITOR based on edit option
if [ -z "$edit" ]; then
	export GIT_EDITOR=":"
fi

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

# Retrieve the commit SHA to fixup
sha=$(git getcommit $force $sha)

# Log the commit SHA to be fixed up
zz_log i "Fix privacy from commit: $sha"

author=$(git log -1 --format='%an <%ae>' $sha)

zz_log i "Using author: $author"s

# verify git config
gitname=$(git config --get user.name)
gitmail=$(git config --get user.email)
if [ -z "$gitname" -o -z "$gitmail" ]; then
	zz_log e "Git user.name or user.email not set"
	exit 1
fi

# Rebase and amend the commit author
git rebase --no-verify --exec "git commit --no-verify --amend --author='$author' --no-edit" $sha^

# if rebase successful and push option is set, push force the changes
if [ "$?" -eq 0 -a -n "$push" ]; then
	# Check if the branch is already pushed
	if git rev-parse --verify --quiet origin/HEAD >/dev/null; then
		zz_log i "Pushing to remote..."
		git push --force-with-lease origin HEAD
	else
		zz_log i "Branch not pushed, skipping push..."
	fi
fi
