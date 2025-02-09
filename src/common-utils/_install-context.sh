#!/bin/sh

### Help
if [ "$1" = "-h" ]; then
    echo "Usage: $0 [target] [source]"
    echo "  target: target directory (default: /usr/local/share/<feature>)"
    echo "  source: source directory (default: dirname of the caller script)"
    exit 1
fi

### Init directories
if [ "$(uname -o)" = "Msys" ]; then
    caller_filename=$(tr -d '\0' </proc/$PPID/cmdline | sed 's/--.*//')
else
    caller_filename=$(ps -o args= $PPID)
fi

caller_filepath=$(readlink -f ${caller_filename##/bin/sh})
declare -x source=${2:-$(dirname $caller_filepath)}
declare -x feature=$(basename $source | sed 's/_.*$//')
declare -x target=${1:-/usr/local/share/$feature}

### Create target directory
mkdir -p $target

### Logs
echo "Installing <$feature> from <$source> to <$target>..."
