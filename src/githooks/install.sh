#!/bin/sh
set -e

echo "Activating feature 'githooks'"

### Get current directory
feature=$(dirname $(readlink -f $0))
gitHooks=/usr/local/share/githooks

### Create hooks directory if not exists
mkdir -p $gitHooks

### For each sh hook starting with _ in the feature directory, copy it to the hooks directory
echo "Copying hooks to $gitHooks..."
find $feature -type f -name "_*.sh" | while read hook; do
    hookName=$(basename $hook | sed 's/^_//;s/\.sh$//')
    cp $hook $gitHooks/$hookName
    chmod +x $gitHooks/$hookName
    echo "Copied hook $hook => $gitHooks/$hookName"
done

### For each json file starting with _ in the feature directory, copy it to the hooks directory
echo "Copying json files to $gitHooks..."
find $feature -type f -name "_*.json" | while read file; do
    cp $file $gitHooks/$(basename $file)
    echo "Copied $file => $gitHooks/$(basename $file)"
done

### Copy the config script to the hooks directory and create a git alias for it
echo "Creating git alias for githooks configuration..."
cp $feature/configure.sh $gitHooks/configure.sh
chmod +x $gitHooks/configure.sh

### Create git alias to configure hooks behaviors in current repository
git config --system alias.init-hooks "!sh -c '$feature/configure.sh' - "
