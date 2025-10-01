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
    name=$(git branch --list hotfix/* | sed 's/.*hotfix\///')
    zz_log i "Hotfix branch found: {Yellow $name}"
fi

# Check if on a release branch and extract branch name
if [ -n "$(git branch --list release/*)" ]; then
    flow=release
    name=$(git branch --list release/* | sed 's/.*release\///')
    zz_log i "Release branch found: {Blue $name}"
fi

# Check if a flow branch is found from .git/RELEASE file
if [ -z "$flow" ] && [ -f .git/RELEASE ]; then
    flow=release
    name=$(cat .git/RELEASE)
    zz_log i "Release branch found: {Blue $name}"
    if ! git checkout $flow/$named; then
        zz_log e "Cannot switch to $flow/$name branch"
        exit 1
    fi
fi

# Exit if no flow branch is found
if [ -z "$flow" ] || [ -z "$name" ]; then
    zz_log e "No flow branch found"
    exit 1
fi

# Prevent git editor prompt during finish
GIT_EDITOR=:

# Update version, changelog, and finish release
#if npx --yes commit-and-tag-version --commit-all --skip.tag --no-verify; then
GBV=$(bump-changelog -b -m)
if [ "$?" -eq 0 ] && [ -n "$GBV" ]; then
    zz_log s "Version & CHANGELOG updated to: {B $GBV}"
    
    if ! git commit -am "chore(release): $GBV"; then
        zz_log e "Cannot commit version & CHANGELOG"
        exit 1
    else
        git push origin $flow/$name
        zz_log s "Version & CHANGELOG committed and pushed"
    fi

    if git flow $flow finish $name --push --message "git flow release" --showcommands  ; then
        zz_log s "Release finished: {B $GBV}"
        rm -f .git/RELEASE
    else
        zz_log e "Cannot finish release. CHANGELOG & VERSION are not updated."
    fi
else
    zz_log e "Cannot update version & finish release"
fi

# Follow major/minor tags
bump-tag $GBV
