#!/bin/sh

# Source the context script to initialize variables and settings
zz_context "$@"

echo "Installing bin scripts form '$target'..."

# Find all shell scripts in the target directory, make them executable, and create symbolic links in /usr/local/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    # Create a symbolic link in /usr/local/bin with the script name (without the leading underscore and .sh extension)
    link=/usr/local/bin/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link
    echo "Linked '$file' to '$link'"
done
