#!/bin/sh

# Parse arguments and print help if needed
eval $(
    zz_args "Release production branch" $0 "$@" <<-help
help
)

# Change to repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Prefer the branch we're already on, so a checked-out hotfix/release branch
# is never overridden by an unrelated one that also happens to exist locally.
current=$(git branch --show-current)
case "$current" in
hotfix/*)
    flow=hotfix
    name=${current#hotfix/}
    zz_log i "On hotfix branch: {Yellow $name}"
    ;;
release/*)
    flow=release
    name=${current#release/}
    zz_log i "On release branch: {Blue $name}"
    ;;
esac

# Not currently on a flow branch: fall back to discovery, but refuse to guess
# when more than one candidate exists -- silently picking one risks finishing
# (merging + tagging + pushing) the wrong release/hotfix.
if [ -z "$flow" ]; then
    hotfixes=$(git branch --list 'hotfix/*' | sed 's/^[* ]*hotfix\///')
    hotfix_count=$(printf '%s\n' "$hotfixes" | grep -c .)

    if [ "$hotfix_count" -gt 1 ]; then
        zz_log e "Multiple hotfix branches found, checkout the one to finish first: $(printf '%s' "$hotfixes" | tr '\n' ' ')"
        exit 1
    elif [ "$hotfix_count" -eq 1 ]; then
        flow=hotfix
        name=$hotfixes
        zz_log i "Hotfix branch found: {Yellow $name}"
    elif [ -f .git/RELEASE ]; then
        flow=release
        name=$(cat .git/RELEASE)
        zz_log i "Release branch found: {Blue $name}"
    else
        releases=$(git branch --list 'release/*' | sed 's/^[* ]*release\///')
        release_count=$(printf '%s\n' "$releases" | grep -c .)

        if [ "$release_count" -gt 1 ]; then
            zz_log e "Multiple release branches found, checkout the one to finish first: $(printf '%s' "$releases" | tr '\n' ' ')"
            exit 1
        elif [ "$release_count" -eq 1 ]; then
            flow=release
            name=$releases
            zz_log i "Release branch found: {Blue $name}"
        fi
    fi
fi

# Exit if no flow branch is found
if [ -z "$flow" ] || [ -z "$name" ]; then
    zz_log e "No flow branch found"
    exit 1
fi

# Switch to the resolved branch
if ! git checkout "$flow/$name" >/dev/null 2>&1; then
    zz_log e "Cannot switch to $flow/$name branch"
    exit 1
fi
zz_log s "On branch: {Blue $flow/$name}"

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    zz_log e "Working directory is not clean. Please commit or stash changes."
    exit 1
fi


# Ensure main branch has an up to-date remote
if ! git fetch origin >/dev/null 2>&1; then
    zz_log e "Cannot fetch from remote"
    exit 1
fi

# Ensure main branch is up-to-date
if ! git merge-base --is-ancestor "$(git rev-parse "$flow/$name")" "$(git rev-parse "refs/remotes/origin/$flow/$name")" ; then
    zz_log e "$flow/$name branch is not up-to-date with remote. Please pull the latest changes."
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
export GIT_EDITOR=:

# Update version, changelog, and finish release
if bump-changelog -f "$GBV" -b -m; then
    zz_log s "Version & CHANGELOG updated to: {B $GBV}"
    if ! git commit -am "chore(release): $GBV"; then
        zz_log e "Cannot commit version & CHANGELOG"
        exit 1
    else
        git push --set-upstream origin "$flow/$name"
        zz_log s "Version & CHANGELOG committed and pushed"
    fi

    # Ensure develop  branch is up-to-date before finishing release
    if ! git fetch origin develop:develop; then
        zz_log e "Cannot fetch develop branch from remote"
        exit 1
    fi

    if ! git merge-base --is-ancestor $(git rev-parse develop) $(git rev-parse origin/develop) ; then
        zz_log e "Develop branch is not up-to-date with remote. Please pull the latest changes."
        exit 1
    fi

    # git flow finish prepends gitflow.prefix.versiontag to --tagname itself,
    # so pass the bare version here -- prefixing it ourselves would tag "vv$GBV".
    if git flow "$flow" finish "$name" --push --tagname "$GBV" --message "$GBV" ; then
        zz_log s "Release finished: {B $GBV}"
        bump-tag "$GBV"
        # Clear release state only once the release has actually finished.
        rm -f .git/RELEASE
    else
        zz_log e "Cannot finish release. CHANGELOG & VERSION are not updated."
        zz_log - "Please fix the issues, commit the changes, and finish the release manually with:"
        zz_log - "   git flow $flow finish $name --push --tagname $GBV --message $GBV"
        zz_log - "   bump-tag $GBV"
    fi
else
    zz_log e "Cannot update version & finish release"
fi


