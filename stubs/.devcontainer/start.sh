#!/bin/sh

### Make sure the workspace folder is owned by the user
git config --global --add safe.directory ${containerWorkspaceFolder:-.}

### Define gpg configuration
if [ -z "$CODESPACES" ]; then
    git config --global gpg.program gpg2
fi

echo "SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa | tr -d '\n')" >>.github/workflows/.secrets
