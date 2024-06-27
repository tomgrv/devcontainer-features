#!/bin/sh
set -e

echo "Activating feature 'nektos/act'"

### Install Act
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/${VERSION}/install.sh | sudo bash -s -- -b /usr/local/bin
