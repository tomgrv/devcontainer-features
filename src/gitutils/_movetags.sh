#!/bin/bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Checkout the specified branch
git checkout $BRANCH

# Get all tags
TAGS=$(git tag)

# Loop through each tag
for TAG in $TAGS; do
    # Get the commit message of the tag
    TAG_COMMIT=$(git rev-list -n 1 $TAG)

    # Check if the commit exists in the specified branch
    if ! git merge-base --is-ancestor $TAG_COMMIT $BRANCH; then

        TAG_MESSAGE=$(git log -1 --pretty=%B $TAG_COMMIT)

        echo "Message of tag $TAG: $TAG_MESSAGE"

        # Find the commit in the branch with the same message
        NEW_COMMIT=$(git log --pretty=format:"%H" --grep="$TAG_MESSAGE" $BRANCH | head -n 1)

        echo "Nearest commit with the same message: $NEW_COMMIT"

        if [ -n "$NEW_COMMIT" ]; then
            # Move the tag to the new commit
            git tag -f "$TAG" $NEW_COMMIT
            echo "Moved tag $TAG to commit $NEW_COMMIT"
        else
            echo "No matching commit found for tag $TAG in branch $BRANCH"
        fi

    else
        echo "Tag $TAG is already in branch $BRANCH"
    fi
done

# Push the updated tags to the remote repository
git push --tags --force
