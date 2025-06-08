#!/bin/sh

if [ -n "$1" ]; then

    TAG=$(git tag --sort=v:refname | grep "$1" | tail -n1)

    if [ -z "$TAG" ]; then
        echo "No tags found in the repository."
        exit 1
    fi

    echo "Latest tag found: $TAG"

    git tag -f $1 $TAG

else
    TAG=$(git tag --sort=v:refname | tail -n1)

    if [ -z "$TAG" ]; then
        echo "No tags found in the repository."
        exit 1
    fi

    echo "Latest tag found: $TAG"

    git tag -f $(echo $TAG | cut -d. -f1) $TAG
    git tag -f $(echo $TAG | cut -d. -f1-2) $TAG
fi

git push --tags --force
