#!/bin/sh

### Ensure correct access rights
sudo chown -Rf vscode:vscode ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*
sudo chmod -Rf 755 ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*

### Add ssh-keyscan to known_hosts if 
ssh-keyscan github.com >>/home/vscode/.ssh/known_hosts || true
