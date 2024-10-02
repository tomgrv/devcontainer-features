#!/bin/sh
set -e

### Merge all files from stub folder to root with git merge-file
echo "Merging stubs files" 
for file in $(find $source/stubs -type f); do

  ### Get middle part of the path
  folder=$(dirname ${file#$source/stubs/})

  ### Create folder if not exists
  mkdir -p $folder

  ### Merge file
  echo "Merge $folder/$(basename $file)" 
  git merge-file -p $file $folder/$(basename $file) ${folder#$source/}/$(basename $file) >$folder/$(basename $file)

  ### Apply rights
  chmod $(stat -c "%a" $file) $folder/$(basename $file)
done

### Find all file with a trailing slash outside dist folder, make sure they are added to .gitignore and remove the trailing slash
echo "Add files to .gitignore"e
for file in $(find . -type f -name "#*" -not -path "./stubs/*" -not -path "./node_modules/*" -not -path "./vendors/*"); do

  echo "Add $file to .gitignore"

  ### Remove trailing # and leading ./#
  clean=${file#./#}

  ### Add to .gitignore if not already there
  grep -qxF $clean .gitignore || echo "$clean" >>.gitignore

  ### Rename file
  mv $file $clean
done
