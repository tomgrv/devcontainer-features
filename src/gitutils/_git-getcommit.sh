#!/bin/sh

# Function to print help and manage arguments
eval $(
    zz_args "List git history and asks for commit" $0 "$@" <<-help
		    f -        force     allow overwritting pushed history
            p -        previous  show commit previous to the one specified
			- sha      sha       sha commit to fix from after
	help
)

#### Go to repository root
cd "$(git rev-parse --show-toplevel)"

# Fetch updates from the remote repository
git fetch --progress --prune --recurse-submodules=no origin >/dev/null

if [ -z "$sha" ]; then
    if [ -n "$force" ]; then
        zz_log w "Force mode enabled, overwriting pushed history"
        git forceable >&2
        read -p 'Which commit? ' sha
    else
        git fixable >&2
        read -p 'Which commit? ' sha
    fi
fi


#### Display commit to fixup, keep only the sha, remove new line
sha=$(git rev-parse --verify "$sha^{commit}" | cut -d' ' -f1 | tr -d '\n')

if [ -n "$previous" ]; then
    git log --pretty=%P -1 "$sha"
else
    echo "$sha"
fi
