#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Install utils
for bin in $UTILS; do

    zz_log i "Checking {B $bin}..."

    if [ -n "$(command -v $bin)" ]; then
        zz_log s "{B $bin} is installed."
    elif [ -f /etc/alpine-release ]; then
        apk update
        apk add $bin
    elif [ $(uname) = "Linux" ] || [ $(uname) = "Darwin" ]; then
        sudo apt-get update
        sudo apt-get install -y $bin
    elif [ $(uname -o) = "Msys" ]; then
        winget install -s winget -e --name $bin --location /tmp/common-utils
    else
        zz_log w "Please install {B $bin} Manually."
        exit 1
    fi
done >&2
