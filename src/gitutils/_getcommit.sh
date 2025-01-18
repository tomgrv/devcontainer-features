#!/bin/sh

#### Go to repository root
cd "$(git rev-parse --show-toplevel)"

#### Get calling script name without extension and starting _
script=$(basename $0 .sh | sed 's/^_//')

#### Display help
if [ "$1" = '--help' ]; then
    echo 'Usage: git '$script' [--force|<commit>]'
    exit 0
fi

#### List commits to fixup and ask user to choose one
if [ "$1" = "--force" ]; then
    echo 'Get commit to fixup by overwritting pushed history...' >&2
    git forceable >&2
    read -p 'What commit to fix? ' sha
elif [ -z "$1" ]; then
    echo 'Get commit to fixup without overwritting pushed history...' >&2
    git fixable >&2
    read -p 'What commit to fix? ' sha
else
    #### Use given commit
    sha=$1
fi

#### Display commit to fixup, keep only the sha, remove new line
echo $sha | cut -d' ' -f1 | tr -d '\n'

#### Back to previous directory
cd - >/dev/null
