#!/bin/sh
set -e

### Create links to utils in /usr/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file
do
    link=/usr/bin/$(basename $file | sed -e 's/^_//' -e 's/.sh$//')
    rm -f $link || true
    ln -s $file $link || true
done
