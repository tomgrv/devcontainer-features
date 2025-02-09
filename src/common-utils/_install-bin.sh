#!/bin/sh

### Context
. "$(dirname $0)/_install-context.sh" "$@"

### Create links to utils in /usr/local/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    link=/usr/local/bin/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link
done
