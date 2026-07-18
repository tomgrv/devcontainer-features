#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### EXIT IF OTHER RELEASE EXISTS
if [ -f .git/RELEASE ] && [ -n "$(git branch --list 'release/*' | grep -v "$(cat .git/RELEASE)")" ]; then
    zz_log e "Other release exists, cannot proceed"
    exit 1
fi

#### GET BUMP VERSION
GBV=$(gv -showvariable MajorMinorPatch)
if [ -z "$GBV" ]; then
    zz_log e "Cannot compute release version"
    exit 1
fi

#### PREVENT GIT EDITOR PROMPT
export GIT_EDITOR=:

#### START RELEASE
# Record the release state only once the branch actually exists, so a failed
# start does not leave a stale .git/RELEASE behind for `git prod`/next `git beta`.
if git flow release start "$GBV"; then
    printf '%s\n' "$GBV" >.git/RELEASE
    git push origin "release/$GBV"
else
    zz_log e "Failed to start release $GBV"
    exit 1
fi
