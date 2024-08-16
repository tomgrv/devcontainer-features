#!/bin/sh
set -e

### Define hook directory
git config core.hooksPath .git/hooks

### Make a symbolic link to the hook directory for each hook starting with '_'  and ending with '.sh'
find $source -name '_*.sh' | sort | while read file; do
    hook=$(basename $file | sed 's/^_//;s/\.sh$//')
    echo "Link $file to .git/hooks/$hook" | npx chalk-cli --stdin yellow
    ln -sf $file .git/hooks/$hook
done
