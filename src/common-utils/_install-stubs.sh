#!/bin/sh

# Source colors script
. zz_colors

# Source the context script to initialize variables and settings
eval $(
    zz_context "$@"
)

if [ -z "$feature" ]; then
    echo "Usage: install-stubs <feature>"
    exit 1
fi

echo "Installing stubs from <${Purple}$feature${None}>..."

# Merge all files from the stubs folder to the root with git merge-file
for file in $(find $source/stubs -type f -name ".*" -o -type f); do

    # Get the relative of the path
    folder=$(dirname ${file#$source/stubs/})
    dest=$folder/$(basename $file | sed 's/\.\./\./g')

    # Create the folder if it does not exist
    mkdir -p $folder

    # if filename starts with #, add it to .gitignore without the #
    if [ $(basename $file | cut -c1) = "#" ]; then

        # Remove # occurrences in the file path
        dest=$(echo $dest | sed 's/\/\#/\//g')

        echo "Add '$dest' to .gitignore"

        # Add to .gitignore if not already there
        grep -qxF $dest .gitignore || echo "$dest" >>.gitignore
    fi

    # Merge the file
    echo "${Yellow}Merging '$dest'...${None}"
    git merge-file -p -L current -L base -L stubs $dest /dev/null $file >$dest

    # Apply the same permissions as the original file
    chmod $(stat -c "%a" $file) $dest

done
