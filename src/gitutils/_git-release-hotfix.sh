#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Parse arguments and print help if needed
eval $(
    zz_args "Create HotFix branch" $0 "$@" <<-help
help
)

#### GET last vX.Y.Z tag on the main branch, removing the leading 'v' and replacing last number with 'X'
current=$(git describe --tags --abbrev=0 --match "v[0-9]*.[0-9]*.[0-9]*" main | sed -e 's/^v//' -e 's/\.[0-9]*$/.X/')

#### SAVE CURRENT STATUS
git stash --include-untracked --message "Before $current" --keep-index   

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=:

#### START HOTFIX
git flow hotfix start $current

#### RESTORE STATUS
git stash apply
