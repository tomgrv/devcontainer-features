#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

### Ensure "prepare": "husky" is wired into package.json so `npm install`
### keeps `.husky/` up to date on every future install (husky v9+ runs the
### bare `husky` command from the npm `prepare` lifecycle script, not
### `husky install`).
jq -n '{"scripts": {"prepare": "husky"}}' | merge-json -t "${tabSize:-4}" package.json -

### `devcontainer create` doesn't run `npm install` interactively at this
### point, so `.husky/` wouldn't exist yet if we only relied on the
### `prepare` lifecycle script - initialize it imperatively now, same
### reasoning as configure-hooks.sh writing hook files directly.
npx --yes husky && zz_log s "Initialized {U .husky}"
