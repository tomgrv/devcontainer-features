#!/bin/sh
set -e

### Create links to utils in /usr/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file
do
    ln -s $file /usr/bin/$(basename $file | sed -e 's/^_//' -e 's/.sh$//')
done
