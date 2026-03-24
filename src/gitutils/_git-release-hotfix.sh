#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Parse arguments and print help if needed
eval $(
    zz_args "Create HotFix branch" $0 "$@" <<-help
        r -         rebase      force rebase of current commits onto hotfix branch
        s -         stash       stash current staged changes before creating hotfix branch and reapply them after
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
elif git log --reverse --pretty=oneline --format=%B develop --not origin/develop --no-merges | grep -vE "^$|^fix(\(.+\))?:" >/dev/null; then
    zz_log w "There are commits since $main that are not of type 'fix:', creating hotfix branch only"
    unset rebase
elif [ -z "$stash" ]; then
    zz_log i "All commits since $main are of type 'fix:', creating hotfix branch and rebasing current history + stash on top of it"
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

    if [ -n "$stash" ]; then
        zz_log w "Working directory is not clean. Stashing staged changes before creating hotfix branch..."
        git stash save -k -m "Hotfix stash: $(date +%Y-%m-%d-%H-%M-%S)"
    else
        zz_log e "Working directory is not clean. Please commit or stash changes. Use -s option to automatically stash and reapply changes."
        exit 1
    fi
else
    zz_log i "Working directory is clean, no need to stash changes"
    unset stash
fi

# Set GIT_EDITOR to no-op to avoid opening editor during rebase or cherry-pick
GIT_EDITOR=:

hotfix=$(echo "$main" | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2.X/')

# Create hotfix branch
git flow hotfix start $hotfix

# If stash was used, pop it back
if [ -n "$stash" ]; then
    zz_log i "Applying stashed changes..."
    git stash pop --index
fi

# If rebase needed, 
# pick all "fix" commits from develop branch and rebase them onto hotfix branch,
# then reset develop branch to the main tag
if [ -n "$rebase" ]; then

    zz_log i "Rebasing develop commits onto hotfix branch..."
    git fix base -p hotfix/$hotfix develop

fi
    
        