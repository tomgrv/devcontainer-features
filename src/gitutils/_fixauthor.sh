#!/bin/sh
# Check if at least one old email is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <old-email-1> [<old-email-2> ... <old-email-n>]"
  exit 1
fi

OLD_EMAILS=$@
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
envfilter="for OLD_EMAIL in $OLD_EMAILS; do                
  if test \"\$GIT_COMMITTER_EMAIL\" = \"\$OLD_EMAIL\"; then  
    export GIT_COMMITTER_NAME=\"$CORRECT_NAME\"             
    export GIT_COMMITTER_EMAIL=\"$CORRECT_EMAIL\"           
  fi                                                         
  if test \"\$GIT_AUTHOR_EMAIL\" = \"\$OLD_EMAIL\"; then     
    export GIT_AUTHOR_NAME=\"$CORRECT_NAME\"                
    export GIT_AUTHOR_EMAIL=\"$CORRECT_EMAIL\"              
  fi                                                        
done"

#### Rewrite history to fix author
git filter-branch --env-filter "$envfilter" --tag-name-filter cat -- --all

# Clean up the original refs
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
