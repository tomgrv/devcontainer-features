#!/bin/sh

## get the branch name whatever the form is
branch=$(git rev-parse --abbrev-ref HEAD)

## get the remote branch name
origin=$(git config --get branch.$branch.remote)

git fetch $origin && git branch -m $branch $branch-to-delete && git checkout -b $branch $origin/$branch && git branch -D $branch-to-delete
