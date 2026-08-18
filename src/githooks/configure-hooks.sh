#!/bin/sh

### Define hook directory
git config core.hooksPath .git/hooks

### Make a symbolic link to the hook directory for each script in bin/
find $source/bin -name '*.sh' | sort | while read file; do
    hook=$(basename $file | sed 's/\.sh$//')
    { 
        ln -sf $file .git/hooks/$hook && sudo chmod +x .git/hooks/$hook
    } && zz_log s "Linked {U $file} to {U .git/hooks/$hook}"
done
