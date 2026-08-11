#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Set permissions and ownership for workspace files
zz_log i "Setting permissions and ownership for workspace files..."
sudo find "${containerWorkspaceFolder:-.}" -mindepth 1 -type d -exec chmod 755 {} +
sudo find "${containerWorkspaceFolder:-.}" -mindepth 1 -exec chown vscode:vscode {} +

git config --global --add safe.directory "${containerWorkspaceFolder:-.}"
