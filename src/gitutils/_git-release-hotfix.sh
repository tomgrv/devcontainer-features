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
elif git log "$main"..HEAD --pretty=%B | grep -v -E '^fix(\(.+\))?: ' | grep -E '^[a-zA-Z]' >/dev/null; then
    zz_log w "There are commits since $main that are not of type 'fix:', creating hotfix branch and reapplying stash"
    rebase=false
else
    zz_log i "All commits since $main are of type 'fix:', creating hotfix branch and rebasing current history + stash on top of it"
    rebase=true
fi

# If rebase needed, check that develop branch has not been pushed since last tag
if [ -n "$rebase" ]; then
    if [ "$(git rev-parse develop)" != "$(git rev-parse origin/develop)" ]; then
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
    
    # Store current branch heads
    develop_head=$(git rev-parse develop)
    hotfix_head=$(git rev-parse "hotfix/$current")
    
    # Pick all "fix" commits from develop and rebase them onto hotfix branch
    zz_log i "Cherry-picking fix commits from develop branch..."
    
    # Get all fix commits from develop since the main tag
    fix_commits=$(git log --reverse --pretty=format:"%H" "$main"..develop --grep="^fix")
    
    if [ -n "$fix_commits" ]; then
        # Cherry-pick each fix commit onto the hotfix branch
        echo "$fix_commits" | while read commit; do
            
                zz_log i "Cherry-picking commit: $(git log --oneline -1 $commit)"
                if ! git cherry-pick "$commit"; then
                    zz_log e "Failed to cherry-pick commit $commit"
                    zz_log i "Please resolve conflicts and run 'git cherry-pick --continue'"
                    exit 1
                fi
        done
        zz_log s "Successfully cherry-picked all fix commits"

        # Now, remove the fix commits on develop branch that are now on hotfix
        echo "$fix_commits" | while read commit; do
            
            if ! git checkout develop && git revert --no-commit "$commit"; then
                zz_log e "Failed to revert commit $commit on develop"
                exit 1
            fi
          
        done


    else
        zz_log i "No fix commits found to cherry-pick"
    fi
    
    # Reset develop branch to the main tag (removing the fix commits that are now on hotfix)
    git checkout develop
    git reset --hard "$main"
    zz_log i "Reset develop branch to $main"
    
    # Return to hotfix branch
    git checkout "hotfix/$current"
    
    zz_log s "Successfully inverted develop and hotfix branches"
fi
    
