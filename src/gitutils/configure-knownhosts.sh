#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

mkdir -p ~/.ssh && chmod 700 ~/.ssh && timeout 10 ssh-keyscan -T 5 github.com >>~/.ssh/known_hosts

