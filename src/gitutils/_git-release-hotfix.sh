#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### GET last vX.Y.Z tag on the main branch
last=$(git describe --tags --abbrev=0 --match "v[0-9]*.[0-9]*.[0-9]*" main | sed 's/^v//')

#### SAVE CURRENT STATUS
git stash save --include-untracked "Before hotfix/$last"

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=:

#### START HOTFIX
git flow hotfix start $last

#### RESTORE STATUS
git stash apply
