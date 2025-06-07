#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### GET BUMP VERSION
MAJOR=$(gitversion -config .gitversion -showvariable Major)
MINOR=$(gitversion -config .gitversion -showvariable Minor)

#### SAVE CURRENT STATUS
git stash save --all "Before hotfix/$MAJOR.$MINOR.X"

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=:

#### START HOTFIX
git flow hotfix start $MAJOR.$MINOR.X

#### RESTORE STATUS
git stash apply
