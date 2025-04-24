#!/bin/sh

### Ensure correct access rights
sudo chown -Rf vscode:vscode ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*
sudo chmod -Rf 755 ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*

### Ensure SSH keys are available
for f in known_hosts id_rsa; do
    if [ -f "/home/root/.ssh/$f" ]; then
        sudo cp /home/root/.ssh/$f /home/vscode/.ssh/$f
        sudo chown vscode:vscode /home/vscode/.ssh/$f
        sudo chmod 600 /home/vscode/.ssh/$f
    fi
done

ssh-keyscan github.com >>/home/vscode/.ssh/known_hosts
