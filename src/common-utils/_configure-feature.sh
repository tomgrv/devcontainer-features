#!/bin/sh

script_dir=$(dirname "$(readlink -f "$0")")

# Source colors script
. "$script_dir/_zz_colors.sh"

# Source the argument parsing script to handle input arguments
eval $(
    "$script_dir/_zz_args.sh" "Configure specified feature" $0 "$@" <<-help
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

"$script_dir/_zz_log.sh" i "Configure feature <{Purple $feature}>"
"$script_dir/_zz_log.sh" - "In {U $(pwd)}"
"$script_dir/_zz_log.sh" - "From {U $source}"

# Ensure the source directory exists
if [ ! -d $source ]; then
    "$script_dir/_zz_log.sh" e "Source directory <$source> does not exist"
    exit 1
fi

# Deploy stubs if existing
if [ -d $source/stubs ]; then

    "$script_dir/_zz_log.sh" i "Deploy stubs"

    find $source/stubs -type f -name ".*" -o -type f | while read file; do

        # Get the relative of the path
        folder=$(dirname ${file#$source/stubs/})

        # Get the destination file path
        dest=$folder/$(basename $file | sed 's/\.\./\./g')

        # Create the folder if it does not exist
        mkdir -p $folder

        # if filename starts with #, add it to .gitignore without the #
        if [ "$(basename $file | cut -c1)" = "#" ]; then

            # Remove # occurrences in the file path
            dest=$(echo $dest | sed 's/\/\#/\//g')

            # Add to .gitignore if not already there
            "$script_dir/_zz_log.sh" i "Add {U $dest} to .gitignore"

            # Add to .gitignore if not already there
            grep -qxF $dest .gitignore || echo "$dest" >>.gitignore
        fi

        # Use git merge-file to merge the file
        if [ -f $dest ]; then

            # if json file, use merge-json to merge the file
            if [ "$(basename $file | cut -d. -f2)" = "json" ]; then
                "$script_dir/_zz_log.sh" i "Merging {U $file} into {U $dest}..."
                "$script_dir/_merge-json.sh" -t ${tabSize:-4} $dest $file
            else
                "$script_dir/_zz_log.sh" i "Using git merge-file to merge {U $file} into {U $dest}..."
                git merge-file -q $dest $file $file
            fi
            
        else
            "$script_dir/_zz_log.sh" i "Destination file {U $dest} does not exist. Copying {U $file} to {U $dest}..."
            cp $file $dest
        fi

        # Apply the same permissions as the original file
        chmod $(stat -c "%a" $file) $dest

    done
fi

# Log the merging process
"$script_dir/_zz_log.sh" i "Merge all package folder json files into top level xxx.json"

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
            "$script_dir/_zz_log.sh" i "Merge {U $tmpl} in {U $package}..."

            # Remove comments from the source json and merge it with the target package.json
            "$script_dir/_merge-json.sh" -t ${tabSize:-4} $package $tmpl
        done

        # Reset the tmpl variable
        unset tmpl

    done
done

# if in top level directory, call configure scripts
if [ "$(pwd)" = "$(git rev-parse --show-toplevel)" ]; then

    "$script_dir/_zz_log.sh" s "Running on top level directory!"

    # Call all configure-xxx.sh scripts
    find $source -maxdepth 1 -name configure-*.sh | sort | while read file; do
        "$script_dir/_zz_log.sh" i "Calling {U $file}..."
        sh -c "$file" && "$script_dir/_zz_log.sh" s "Done!" || "$script_dir/_zz_log.sh" e "Failed!"
    done
else
    "$script_dir/_zz_log.sh" w "Not in top level directory, skipping configure scripts"
fi
