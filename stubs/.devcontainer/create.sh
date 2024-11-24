#!/bin/sh

### Ensure correct access rights
sudo chown -Rf $(id -un):$(id -gn) ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*
sudo chmod -Rf 755 ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*
