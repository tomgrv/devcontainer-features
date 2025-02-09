#!/bin/sh

# Source the context script to initialize variables and settings
. zz_context "$@"

echo "Installing stubs from <$feature>..."

# Merge all files from the stubs folder to the root with git merge-file
for file in $(find $source/stubs -type f); do

    # Get the middle part of the path
    folder=$(dirname ${file#$source/stubs/})

    # Create the folder if it does not exist
    mkdir -p $folder

    # Merge the file
    echo "Merge $folder/$(basename $file)"
    git merge-file -p $file $folder/$(basename $file) ${folder#$source/}/$(basename $file) >$folder/$(basename $file)

    # Apply the same permissions as the original file
    chmod $(stat -c "%a" $file) $folder/$(basename $file)
done

# Find all files with a trailing slash outside the dist folder, make sure they are added to .gitignore and remove the trailing slash
echo "Add files to .gitignore"
for file in $(find . -type f -name "#*" ! -path "*/stubs/*" ! -path "./node_modules/*" ! -path "./vendors/*"); do

    echo "Add $file to .gitignore"

    # Remove # occurrences in the file path
    clean=${file#./#}

    # Add to .gitignore if not already there
    grep -qxF $clean .gitignore || echo "$clean" >>.gitignore

    # Rename the file
    mv $file $clean
done
