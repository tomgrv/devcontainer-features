#!/bin/sh

### Add ssh-keyscan to known_hosts (bounded so an unreachable network can't hang container creation)
mkdir -p /home/vscode/.ssh
chmod 700 /home/vscode/.ssh
timeout 10 ssh-keyscan -T 5 github.com >>/home/vscode/.ssh/known_hosts 2>/dev/null || true

### Ensure correct access rights (find, not a `.*` glob, so it can't recurse into the parent directory via `..`)
sudo find ${containerWorkspaceFolder:-.} -mindepth 1 -exec chown vscode:vscode {} +
sudo find ${containerWorkspaceFolder:-.} -mindepth 1 -exec chmod 755 {} +
