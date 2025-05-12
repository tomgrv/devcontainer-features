#!/bin/sh

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Fix git emoji" $0 "$@" <<-help
		- sha    sha       sha commit to fix from after
	help
)

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Rewrite history to fix author
# Rewrite commit messages to add the appropriate emoji from the specified commit
git filter-branch --msg-filter 'npx --yes devmoji -t "$(cat)"' -- ${sha:---all}${sha:+..HEAD}

# Clean up the original refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
