#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

if [ -z "$CODESPACES" ]; then
     git config --global gpg.program gpg2 || true; 
fi
