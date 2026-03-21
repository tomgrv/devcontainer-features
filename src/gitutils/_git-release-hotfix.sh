#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Parse arguments and print help if needed
eval $(
    zz_args "Create HotFix branch" $0 "$@" <<-help
        r -         rebase      force rebase of current commits onto hotfix branch
help
)

#### GET last vX.Y.Z tag on the main branch, removing the leading 'v' and replacing last number with 'X'
main=$(git describe --tags --abbrev=0 --match "v[0-9]*.[0-9]*.[0-9]*" main)

if [ -z "$main" ]; then
    zz_log e "No tag found on main branch"
    exit 1
else
    zz_log i "Current version is $main"
fi

# Check if all commits since the last tag are conventional commits of 'fix:' type
# or if rebase is forced via command line option
if [ -n "$rebase" ]; then
    zz_log i "Rebase forced via command line option, will rebase commits onto hotfix branch"
elif git log  --all --ancestry-path --pretty=format:%s "$main"..HEAD | grep -vE "^(fix(\(.+\))?:|Merge)" >/dev/null; then
    zz_log w "There are commits since $main that are not of type 'fix:', creating hotfix branch only"
    unset rebase
elif [ -z "$stash" ]; then
    zz_log i "All commits since $main are of type 'fix:', creating hotfix branch and rebasing current history onto it"
    rebase=true
fi

# If rebase needed, check that develop branch has not been pushed since last tag
if [ -n "$rebase" ]; then
    if [ "$(git rev-parse develop)" = "$(git rev-parse origin/develop)" ]; then
        zz_log e "Develop branch has been pushed since last tag, cannot rebase safely, aborting"
        exit 1
    fi
fi

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    zz_log e "Working directory is not clean. Please commit or stash changes."
    exit 1
fi

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=:

current=$(echo "$main" | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2.X/')

#### START HOTFIX
git flow hotfix start $current

#### RESTORE STATUS AND HANDLE REBASE
if [ -n "$rebase" ]; then

    zz_log i "Rebasing: inverting develop and hotfix branches..."

    git fix base hotfix/$current develop
fi
    
