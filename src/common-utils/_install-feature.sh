#!/bin/sh
set -e

### Init directories
caller_filename=$(ps -o args= $PPID)
caller_filepath=$(readlink -f ${caller_filename##/bin/sh})
export source=$(dirname $caller_filepath)
export feature=$(basename $source | sed 's/_.*$//')
export target=${1:-/usr/local/share}/$feature

### Logs
echo "Activating feature <$feature>"
echo "from <$source>"
echo "to <$target>"

### Makes sure the target directory exists
mkdir -p $target

### Install specific utils
find $source \( -name "_*" -o -name "configure-*.sh" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

### Call all the install-xxx scripts in the feature directory
echo "Calling all install scripts in $source..."
find $source -type f -name "install-*.sh" | while read script; do
    echo "Calling $script..."
    sh $script
done
