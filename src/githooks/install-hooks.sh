#!/bin/sh
set -e

### For each sh hook starting with _ in the feature directory, copy it to the hooks directory
echo "Copying hooks to $target..."
find $source -type f -name "_*.sh" | while read hook; do
    hookName=$(basename $hook | sed 's/^_//;s/\.sh$//')
    cp $hook $target/$hookName
    chmod +x $target/$hookName
    echo "Copied hook $hook => $target/$hookName"
done