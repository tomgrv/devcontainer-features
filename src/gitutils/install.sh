#!/bin/sh
set -e

### Init directories
source=$(dirname $(readlink -f $0))
feature=$(basename $source)
target=/usr/local/share/$feature
echo "Activating feature <$feature>..."
mkdir -p $target

### For each json file starting with _ in the feature directory, copy it to the hooks directory
echo "Copying json files to $target..."
find $source -type f -name "_*.json" | while read file; do
    cp $file $target/$(basename $file)
    echo "Copied $file => $target/$(basename $file)"
done

### Copy the config script to the hooks directory and create a git alias for it
echo "Creating git alias for githooks configuration..."
cp $source/configure*.sh $target
chmod +x $target/configure*.sh

### Create git alias to configure hooks behaviors in current repository
git config --system alias.init-$feature "!sh -c '$source/configure.sh' - "

### Call all the install-xxx scripts in the feature directory
echo "Calling all install scripts in $source..."
find $source -type f -name "install-*.sh" | while read script; do
    echo "Calling $script..."
    sh $script
done
