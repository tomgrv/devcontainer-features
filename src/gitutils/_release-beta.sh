#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### EXIT IF OTHER RELEASE EXISTS
if [ -f .git/RELEASE ] && [ -n "$(git branch --list release/* | grep -v $(cat .git/RELEASE))" ]; then
    npx chalk-cli --no-stdin -t "{red Other release exists, cannot proceed}"
    exit 1
fi

#### GET BUMP VERSION
GBV=$(gitversion -config .gitversion -showvariable MajorMinorPatch | tee .git/RELEASE)

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=: 

#### START RELEASE
git flow release start $GBV && git push origin release/$GBV

#### BACK
cd - >/dev/null
