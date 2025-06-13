#!/bin/sh

# Function to print help and manage arguments
eval $(
	zz_args "Fix git emoji" $0 "$@" <<-help
		f -      force     allow overwritting pushed history
		- sha    sha       sha commit to fix from after
	help
)

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

# Retrieve the commit SHA to fixup
sha=$(git getcommit $force $sha)

#### Rewrite history to fix author
# Rewrite commit messages to add the appropriate emoji from the specified commit
git filter-branch --msg-filter 'npx --yes devmoji -t "$(cat)"' --tag-name-filter cat -- --branches --tags ${sha:---all}${sha:+..HEAD}

# Clean up the original refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
