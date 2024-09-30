#!/bin/sh
set -e

### Init directories
export source=$(dirname $(readlink -f $0))
export feature=$(basename $source | sed 's/_.*$//')
export target=${1:-/usr/local/share}/$feature
echo "Activating feature <$feature>..."

### Makes sure the target directory exists
mkdir -p $target

### Copy the config script to the target directory and create a git alias for it
find $source -type f -name "configure*.sh" -exec cp {} $target \;
find $target -type f -name "configure*.sh" -exec chmod +x {} \;

### Call all the install-xxx scripts in the feature directory
echo "Calling all install scripts in $source..."
find $source -type f -name "install-*.sh" | while read script; do
    echo "Calling $script..."
    sh $script
done
