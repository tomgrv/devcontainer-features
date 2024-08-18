#!/bin/sh

# Check if the old email is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <old-email>"
    exit 1
fi

OLD_EMAIL="$1"
CORRECT_NAME=$(git config user.name)
CORRECT_EMAIL=$(git config user.email)

# Check if the correct name and email are available
if [ -z "$CORRECT_NAME" ] || [ -z "$CORRECT_EMAIL" ]; then
    echo "Error: Could not retrieve the current Git user name or email."
    exit 1
fi

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Rewrite history to fix author
git filter-branch --env-filter "
if [ \"\$GIT_COMMITTER_EMAIL\" = \"$OLD_EMAIL\" ]
then
    export GIT_COMMITTER_NAME=\"$CORRECT_NAME\"
    export GIT_COMMITTER_EMAIL=\"$CORRECT_EMAIL\"
fi
if [ \"\$GIT_AUTHOR_EMAIL\" = \"$OLD_EMAIL\" ]
then
    export GIT_AUTHOR_NAME=\"$CORRECT_NAME\"
    export GIT_AUTHOR_EMAIL=\"$CORRECT_EMAIL\"
fi
" --tag-name-filter cat -- --branches --tags
