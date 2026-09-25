#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

### `devcontainer create` doesn't run `npm install` interactively at this
### point, so `.husky/` wouldn't exist yet if we only relied on the
### `prepare` lifecycle script - initialize it imperatively now, same
### reasoning as configure-hooks.sh writing hook files directly.
npx --yes husky && zz_log s "Initialized {U .husky}"
