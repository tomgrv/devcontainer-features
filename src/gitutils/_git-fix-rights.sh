#!/bin/sh

#### GOTO DIRECTORY
root="$(git rev-parse --show-toplevel)"
cd "$root" || exit 1

# Apply the given permission to the tracked files matching the given pathspecs.
# Operates on files tracked by git (not ignored/untracked ones), matching the
# stated intent of normalising the repository's own file permissions.
set_permissions() {
    perm="$1"
    shift
    echo "Setting permissions $perm for: ${*:-<all tracked files>}"
    git ls-files -z "$@" | xargs -0 -r chmod "$perm"
}

# Regular files default to 644, scripts to 755, sensitive files to 600
set_permissions 644
set_permissions 755 '*.sh'
set_permissions 600 '*.conf' '*.env'

# Directories default to 755 (git does not track directories, so derive them
# from the working tree, excluding the .git internals)
find "$root" -type d -not -path '*/.git' -not -path '*/.git/*' -exec chmod 755 {} +

# Tighten well-known sensitive directories (e.g. logs, cache) to 700
find "$root" -type d \( -name logs -o -name cache \) -not -path '*/.git/*' -exec chmod 700 {} +

echo "Access rights have been set according to best practices."
