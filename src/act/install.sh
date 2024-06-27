#!/bin/sh
set -e

echo "Activating feature 'nektos/act'"

### Install Docker with apk on alpine and apt on ubuntu
if [ -f /etc/alpine-release ]; then
    echo "Installing Docker on Alpine"
    apk add docker
elif [ -f /etc/debian_version ]; then
    echo "Installing Docker on Ubuntu"
    sudo apt-get update
    sudo apt-get install -y docker.io
else
    echo "Unsupported OS"
    exit 1
fi

### Install Act
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/${VERSION}/install.sh | sudo bash -s -- -b /usr/local/bin
