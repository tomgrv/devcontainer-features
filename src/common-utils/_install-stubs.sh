#!/bin/sh
set -e

### Init directories
caller_filename=$(ps -o args= $PPID)
caller_filepath=$(readlink -f ${caller_filename##/bin/sh})
export source=$(dirname $caller_filepath)
export feature=$(basename $source | sed 's/_.*$//')
export target=${1:-/usr/local/share}/$feature

### Logs
echo "Merging stubs files of <$feature>"
echo "from <$source>"
echo "to <$target>"

### Merge all files from stub folder to root with git merge-file
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
echo "Add files to .gitignore"
for file in $(find . -type f -name "#*" ! -path "*/stubs/*" ! -path "./node_modules/*" ! -path "./vendors/*"); do

  echo "Add $file to .gitignore"

  ### Remove # occurences in file path
  clean=${file#./#}

  ### Add to .gitignore if not already there
  grep -qxF $clean .gitignore || echo "$clean" >>.gitignore

  ### Rename file
  mv $file $clean
done
