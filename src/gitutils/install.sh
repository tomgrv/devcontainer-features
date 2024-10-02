#!/bin/sh
set -e

### Check if utils are installed
utils() {
    for bin in $* dos2unix jq; do
        if [ -n "$(command -v $bin)" ]; then
            echo "$bin is installed."
        elif [ -f /etc/alpine-release ]; then
            apk update
            apk add $bin
        elif [ $(uname) = "Linux" ] || [ $(uname) = "Darwin" ]; then
            sudo apt-get update
            sudo apt-get install -y $bin
        else
            echo "Please install $bin."
            exit 1
        fi
    done
} && utils git-flow

### Init directories
export source=$(dirname $(readlink -f $0))
export feature=$(basename $source | sed 's/_.*$//')
export target=${1:-/usr/local/share}/$feature
echo "Activating feature <$feature>..."

### Makes sure the target directory exists
mkdir -p $target

### Copy the config script to the target directory and create a git alias for it
find $source \( -name "_*" -o -name "configure*.sh" \) -type f -exec cp {} $target \;
find $target -type f -name "*.sh" -exec chmod +x {} \;

### Call all the install-xxx scripts in the feature directory
echo "Calling all install scripts in $source..."
find $source -type f -name "install-*.sh" | while read script; do
    echo "Calling $script..."
    sh $script
done
