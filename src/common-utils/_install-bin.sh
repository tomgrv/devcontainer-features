#!/bin/sh
set -e

### Init directories
caller_filename=$(ps -o args= $PPID)
caller_filepath=$(readlink -f ${caller_filename##/bin/sh})
export source=$(dirname $caller_filepath)
export feature=$(basename $source | sed 's/_.*$//')
export target=${1:-/usr/local/share}/$feature

### Create links to utils in /usr/local/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file
do
    link=/usr/local/bin/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link
done
