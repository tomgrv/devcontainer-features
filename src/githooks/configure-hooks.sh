#!/bin/sh

### Define hook directory
git config core.hooksPath .git/hooks

### Make a symbolic link to the hook directory for each hook starting with '_'  and ending with '.sh'
find $source -name '_*.sh' | sort | while read file; do
    hook=$(basename $file | sed 's/^_//;s/\.sh$//')
    ln -sf $file .git/hooks/$hook && zz_log s "Linked {U $file} to {U .git/hooks/$hook}"
done
