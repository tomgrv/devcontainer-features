#!/bin/sh

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Release production branch" $0 "$@" <<-help
	help
)

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### CHECK IF ON A HOTFIX BRANCH, EXTRACT BRANCH NAME
if [ -n "$(git branch --list hotfix/*)" ]; then
    flow=hotfix
    name=$(git branch --list hotfix/* | sed 's/.*hotfix\///')
    zz_log i "Hotfix branch found: {Yellow $name}"
fi

#### CHECK IF ON A RELEASE BRANCH, EXTRACT BRANCH NAME
if [ -n "$(git branch --list release/*)" ]; then
    flow=release
    name=$(git branch --list release/* | sed 's/.*release\///')
    zz_log i "Release branch found: {Blue $name}"
fi

#### CHECK IF A FLOW BRANCH IS FOUND
if [ -z "$flow" ] && [ -f .git/RELEASE ]; then
    flow=release
    name=$(cat .git/RELEASE)
    zz_log i "Release branch found: {Blue $name}"
    git checkout $flow/$name
fi

#### EXIT IF NO FLOW BRANCH IS FOUND
if [ -z "$flow" ] || [ -z "$name" ]; then
    zz_log e "No flow branch found"
    exit 1
fi

#### GET BUMP VERSION
GBV=$(gitversion -config .gitversion -showvariable MajorMinorPatch)
if [ -z "$GBV" ]; then
    zz_log e "Cannot get version from .gitversion"
    exit 1
fi

zz_log i "Bump version: {Blue $GBV}"

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=:

#### UPDATE VERSION & CHANGELOG & FINISH RELEASE
if npx --yes commit-and-tag-version --skip.tag --no-verify --release-as $GBV; then
    if git flow $flow finish $name --tagname $GBV --message $GBV --push; then
        zz_log s "Release finished: {B $GBV}"
        rm -f .git/RELEASE
    else
        git undo
        zz_log e "Cannot finish release. CHANGELOG & VERSION are not updated."
    fi
else
    zz_log e "Cannot update version & finish release"
fi
