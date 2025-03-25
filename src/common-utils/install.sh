#!/bin/sh

### Options
UTILS="${UTILS:-"jq dos2unix"}"

### Prepare for installation
for util in "colors" "args" "context" "json" "log"; do
    ln -sf $PWD/$(dirname $0)/_zz_${util}.sh $PWD/$(dirname $0)/zz_${util}
done
export PATH=$PWD/$(dirname $0):$PATH

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

### Run Installers
$(dirname $0)/_install-feature.sh -s $PWD/$(dirname $0)
$(dirname $0)/_install-bin.sh -s $PWD/$(dirname $0)
