#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

zz-use zz-install

### Install utils
for bin in $UTILS; do

    zz-log i "Checking {B $bin}..."

    if [ -n "$(command -v $bin)" ]; then
        zz-log s "{B $bin} is installed."
    else
        zz-install $bin || {
            zz-log w "Please install {B $bin} Manually."
            exit 1
        }
    fi
done >&2
