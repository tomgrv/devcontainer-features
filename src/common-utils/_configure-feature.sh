#!/bin/sh

# Source colors script
. zz_colors

# Source the argument parsing script to handle input arguments
eval $(
    zz_args "Configure specified feature" $0 "$@" <<-help
    s source    source      Force source directory
	- feature	feature		Feature name
help
)

if [ -z "$feature" ]; then
    echo "Usage: configure-feature <feature>${End}"
    exit 1
fi

# Initialize the source directory based on the feature name
export source=${source:-/usr/local/share/$feature}

# Get the indent size from devcontainer.json with jq, default to 2 if not found
export tabSize=4

zz_log i "Configure feature <{Purple $feature}>"
zz_log - "In {U $(pwd)}"
zz_log - "From {U $source}"

# Ensure the source directory exists
if [ ! -d $source ]; then
    zz_log e "Source directory <$source> does not exist"
    exit 1
fi

# Deploy stubs if existing
if [ -d $source/stubs ]; then

    zz_log i "Deploy stubs"

    find $source/stubs -type f -name ".*" -o -type f | while read file; do

        # Get the relative of the path
        folder=$(dirname ${file#$source/stubs/})

        # Get the destination file path
        dest=$folder/$(basename $file | sed 's/\.\./\./g')

        # Create the folder if it does not exist
        mkdir -p $folder

        # if filename starts with #, add it to .gitignore without the #
        if [ $(basename $file | cut -c1) = "#" ]; then

            # Remove # occurrences in the file path
            dest=$(echo $dest | sed 's/\/\#/\//g')

            # Add to .gitignore if not already there
            zz_log i "Add {U $dest} to .gitignore"

            # Add to .gitignore if not already there
            grep -qxF $dest .gitignore || echo "$dest" >>.gitignore
        fi

        # Use git merge-file to merge the file
        if [ -f $dest ]; then
            zz_log i "Using git merge-file to merge {U $file} into {U $dest}..."
            git merge-file -q $dest $file $file
        else
            zz_log i "Destination file {U $dest} does not exist. Copying {U $file} to {U $dest}..."
            cp $file $dest
        fi

        # Apply the same permissions as the original file
        chmod $(stat -c "%a" $file) $dest

    done
fi

# Log the merging process
zz_log i "Merge all package folder json files into top level xxx.json"

for type in package composer; do

    # find all package folder json files in the current directory.
    # Ensure top-level package.json is included
    for package in $(git ls-files -o "$type.json"); do

        # Merge all package folder json files into the top-level package.json
        for tmpl in $(find $source -maxdepth 1 -name _*.$type.json | sort); do

            # Create package.json if it does not exist or is empty
            if [ ! -f $package -o ! -s $package ]; then
                # Create an empty package.json
                echo '{"private": true}' >$package
            fi

            # Merge the tmpl & add keys if not already there. make sure source json does not contain any comments
            zz_log i "Merge {U $tmpl} in {U $package}..."
            zz_json $package | jq --indent ${tabSize:-4} -r -s '.[0] * .[1]' $tmpl - >/tmp/$$.json && mv -f /tmp/$$.json $package

        done

        # Normalize the file if needed
        if [ -n "$tmpl" -a -s $package ]; then
            # Post merge normalize package.json
            zz_log i "Post-merge normalize {U $package}..."
            normalize-json -c -w -a -i -t ${tabSize:-4} $package 2>/dev/null
        else
            zz_log - "No merged $package to normalize"
        fi

        # Reset the tmpl variable
        unset tmpl

    done
done

# if in top level directory, call configure scripts
if [ "$(pwd)" = "$(git rev-parse --show-toplevel)" ]; then

    zz_log s "Running on top level directory!"

    # Call all configure-xxx.sh scripts
    find $source -maxdepth 1 -name configure-*.sh | sort | while read file; do
        zz_log i "Calling {U $file}..."
        sh -c "$file" && zz_log s "Done!" || zz_log e "Failed!"
    done
else
    zz_log w "Not in top level directory, skipping configure scripts"
fi
