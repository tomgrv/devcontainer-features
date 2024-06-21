#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### GET BUMP VERSION
GBV=$(gitversion -config .gitversion -showvariable MajorMinorPatch)

#### SAVE CURRENT STATUS
git stash save --all "Before hotfix/$GBV"

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=: 

#### START HOTFIX
git flow hotfix start $GBV

#### RESTORE STATUS
git stash apply

#### BACK
cd - >/dev/null
