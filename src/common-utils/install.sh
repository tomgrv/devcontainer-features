#!/bin/sh

### Options
UTILS="${UTILS:-"jq dos2unix"}"

### Link to utils, retrieve name after _zz_ / before .sh and create a symlink
find $PWD/$(dirname $0) -type f -name "_zz_*.sh" -exec basename {} \; | sed 's/_zz_\(.*\)\.sh/\1/' | while read util; do
    chmod +x $PWD/$(dirname $0)/_zz_${util}.sh
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
