#!/bin/sh

# Source colors script
. zz_colors

# Source the context script to initialize variables and settings
eval $(
    zz_context "$@"
)

if [ -z "$feature" ]; then
    echo "Usage: install-bin <feature>"
    exit 1
fi

echo "Installing bin scripts for <${Purple}$feature${None}>..."

# Find all shell scripts in the target directory, make them executable, and create symbolic links in /usr/local/bin
find $target -type f -name "_*.sh" -exec echo {} \; -exec chmod +x {} \; | while read file; do
    # Create a symbolic link in /usr/local/bin with the script name (without the leading underscore and .sh extension)
    link=/usr/local/bin/$(basename $file | sed 's/^_//;s/.sh$//')
    ln -sf $file $link
    echo "${Green}Linked '$file' to '$link'${None}"
done
