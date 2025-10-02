#!/bin/sh

# Parse arguments and print help if needed
eval $(
    zz_args "Release production branch" $0 "$@" <<-help
help
)

# Change to repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Check if on a hotfix branch and extract branch name
if [ -n "$(git branch --list hotfix/*)" ]; then
    flow=hotfix
    name=$(git branch --list hotfix/* | sed 's/.*hotfix\///'| head -n1 )
    zz_log i "Hotfix branch found: {Yellow $name}"
fi

# Check if on a release branch and extract branch name
if [ -n "$(git branch --list release/*)" ]; then
    flow=release
    name=$(git branch --list release/* | sed 's/.*release\///' | head -n1 )
    zz_log i "Release branch found: {Blue $name}"
fi

# Check if a flow branch is found from .git/RELEASE file
if [ -z "$flow" ] && [ -f .git/RELEASE ]; then
    flow=release
    name=$(cat .git/RELEASE)
    zz_log i "Release branch found: {Blue $name}"
fi

# Exit if no flow branch is found
if [ -z "$flow" ] || [ -z "$name" ]; then
    zz_log e "No flow branch found"
    exit 1
fi

# Extract branch name 
if ! git checkout $flow/$name >/dev/null 2>&1; then
    zz_log e "Cannot switch to $flow/$name branch"
    exit 1
fi
zz_log s "On branch: {Blue $flow/$name}"

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    zz_log e "Working directory is not clean. Please commit or stash changes."
    exit 1
fi

# Get the new version from gitversion
GBV=$(gv -showvariable MajorMinorPatch)
if [ -z "$GBV" ]; then
    zz_log e "Cannot get version from .gitversion"
    exit 1
fi
zz_log i "Bump version: {Blue $GBV}"

# Prevent git editor prompt during finish
GIT_EDITOR=:

# Update version, changelog, and finish release
if bump-changelog -f $GBV -b; then
    zz_log s "Version & CHANGELOG updated to: {B $GBV}" 
    if ! git commit -am "chore(release): $GBV"; then
        zz_log e "Cannot commit version & CHANGELOG"
        exit 1
    else
        git push origin $flow/$name
        zz_log s "Version & CHANGELOG committed and pushed"
    fi

    if git flow $flow finish $name --push --tagname $GBV --message $GBV ; then
        zz_log s "Release finished: {B $GBV}"
        rm -f .git/RELEASE

        # Create git tag for the new version
        bump-tag $GBV
    else
        git undo
        zz_log e "Cannot finish release. CHANGELOG & VERSION are not updated."
    fi
else
    zz_log e "Cannot update version & finish release"
fi


