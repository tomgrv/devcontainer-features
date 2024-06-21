#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### CHECK IF ON A HOTFIX BRANCH, EXTRACT BRANCH NAME
if [ -n "$(git branch --list hotfix/*)" ]; then
    flow=hotfix
    name=$(git branch --list hotfix/* | sed 's/.*hotfix\///')
    npx chalk-cli -t "{green ✔} Hotfix branch found: {yellow $name}"
fi

#### CHECK IF ON A RELEASE BRANCH, EXTRACT BRANCH NAME
if [ -n "$(git branch --list release/*)" ]; then
    flow=release
    name=$(git branch --list release/* | sed 's/.*release\///')
    npx chalk-cli -t "{green ✔} Release branch found: {blue $name}"
fi

#### CHECK IF A FLOW BRANCH IS FOUND
if [ -z "$flow" ] && [ -f .git/RELEASE ]; then
    flow=release
    name=$(cat .git/RELEASE)

    npx chalk-cli -t "{green ✔} Release branch found: {blue $name}"
    git checkout $flow/$name
fi

#### EXIT IF NO FLOW BRANCH IS FOUND
if [ -z "$flow" ] || [ -z "$name" ]; then
    npx chalk-cli -t "{red ✘} No flow branch found"
    exit 1
fi

#### GET BUMP VERSION
GBV=$(gitversion -config .gitversion -showvariable MajorMinorPatch)
npx chalk-cli -t "{green ✔} Bump version: {green $GBV}"

#### PREVENT GIT EDITOR PROMPT
GIT_EDITOR=:

#### UPDATE VERSION & CHANGELOG & FINISH RELEASE
if npx json --validate -q -f package.json && npx commit-and-tag-version --skip.tag --no-verify --release-as $GBV; then
    if git flow $flow finish $name --tagname $GBV --message $GBV --push; then
        npx chalk-cli -t "{green ✔} Release finished: {blue $name -> $GBV}"
        rm -f .git/RELEASE
    else
        git undo
        npx chalk-cli -t "{red ✘} Cannot finish release. CHANGELOG & VERSION are not updated."
    fi
else
    npx chalk-cli -t "{red ✘} Cannot update version & finish release"
fi

#### BACK
cd - >/dev/null
