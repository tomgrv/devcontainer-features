#!/bin/sh

# Function to print help and manage arguments
eval $(
    zz_args "List git history and asks for commit" $0 "$@" <<-help
		    f -        force     allow overwritting pushed history
			- sha      sha       sha commit to fixup
	help
)

#### Go to repository root
cd "$(git rev-parse --show-toplevel)"

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

if [ -n "$force" ]; then
    zz_log w "Force mode enabled, overwriting pushed history"
    git forceable >&2
    read -p 'Whish commit? ' sha
elif [ -z "$sha" ]; then
    git fixable >&2
    read -p 'Which commit? ' sha
else
    #### Use given commit
    sha=$1
fi

#### Display commit to fixup, keep only the sha, remove new line
echo $sha | cut -d' ' -f1 | tr -d '\n'
