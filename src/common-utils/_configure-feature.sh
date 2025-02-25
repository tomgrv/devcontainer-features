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
    echo "Usage: configure-feature <feature>"
    exit 1
fi

# Initialize the source directory based on the feature name
export source=${source:-/usr/local/share/$feature}

# Get the indent size from devcontainer.json with jq, default to 2 if not found
export tabSize=4

echo "Configuring feature <${Purple}$feature${None}>"
echo "from <$source>"

# Go to the module root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Deploy stubs if existing
if [ -d $source/stubs ]; then

    echo "${Blue}Deploy stubs${None}"

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
fi

# Log the merging process
echo "${Blue}Merge all package folder json files into top level xxx.json${None}"

for package in package composer; do

    # Create package.json if it does not exist or is empty
    if [ ! -f $package.json -o ! -s $package.json ]; then
        # Create an empty package.json
        echo "{}" >$package.json
    else
        # Pre-sort the existing package.json
        normalize-json -t ${tabSize:-4} $package.json
    fi

    # Merge all package folder json files into the top-level package.json
    find $source -maxdepth 1 -name _*.$package.json | sort | while read file; do
        echo "${Yellow}Merge $file${None}"
        jq --indent ${tabSize:-4} -s '.[0] * .[1]' $file $package.json >/tmp/$package.json && mv -f /tmp/$package.json $package.json
    done

done

# Call all configure-xxx.sh scripts
find $source -maxdepth 1 -name configure-*.sh | sort | while read file; do
    echo "${Yellow}Run $file${None}"
done
