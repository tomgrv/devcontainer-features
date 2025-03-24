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
zz_log - "From {U $source}"

# Go to the module root
cd "$(git rev-parse --show-toplevel)" >/dev/null

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
            grep -qxF $dest .gitignore || echo -e "$dest" >>.gitignore
        fi

        # Merge the file
        zz_log i "Merge {U $file} in {U $dest}"
        git merge-file -p -L current -L base -L stubs $dest /dev/null $file >$dest

        # Apply the same permissions as the original file
        chmod $(stat -c "%a" $file) $dest

    done
fi

# Log the merging process
zz_log i "Merge all package folder json files into top level xxx.json"

for package in package composer; do

    # Create package.json if it does not exist or is empty
    if [ ! -f $package.json -o ! -s $package.json ]; then
        # Create an empty package.json
        echo "{}" >$package.json
    fi

    # Merge all package folder json files into the top-level package.json
    find $source -maxdepth 1 -name _*.$package.json | sort | while read file; do
        zz_log i "Merge {U $file} in {U $package.json}"
        jq --indent ${tabSize:-4} -s '.[0] * .[1]' $file $package.json >/tmp/$package.json && mv -f /tmp/$package.json $package.json
    done

    # Post merge normalize package.json
    zz_log i "Post-merge normalize {U $package.json}"
    normalize-json -c -w -a -i -t ${tabSize:-4} $package.json
done

# Call all configure-xxx.sh scripts
find $source -maxdepth 1 -name configure-*.sh | sort | while read file; do
    zz_log i "Run {U $file}"
    $file
done
