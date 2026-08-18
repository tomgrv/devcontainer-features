#!/bin/sh

### Options
UTILS="${UTILS:-"jq dos2unix"}"

# Resolve this script's directory as an absolute path, regardless of whether
# $0 was invoked relatively (cd src/common-utils && sh install.sh) or with an
# already-absolute path (sh "$source/src/common-utils/install.sh", as used by
# install-feat.sh / npx)
dir=$(dirname $(readlink -f $0))

### Link to utils, retrieve name before .sh and create a symlink
find $dir/bin -type f -name "zz_*.sh" -exec basename {} \; | sed 's/\.sh$//' | while read util; do
    chmod +x $dir/bin/${util}.sh
    ln -sf $dir/bin/${util}.sh $dir/${util}
done
export PATH=$dir:$PATH

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
$dir/bin/zz_feature.sh -i -s $dir
