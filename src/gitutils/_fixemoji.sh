#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Rewrite history to fix author
# Rewrite commit messages to add the appropriate emoji
git filter-branch --msg-filter 'npx --yes devmoji -t "$(cat)"' -- --all

# Clean up the original refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
