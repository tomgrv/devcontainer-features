#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

zz_use zz_install

### Install utils
for bin in $UTILS; do

    zz_log i "Checking {B $bin}..."

    if [ -n "$(command -v $bin)" ]; then
        zz_log s "{B $bin} is installed."
    else
        zz_install $bin || {
            zz_log w "Please install {B $bin} Manually."
            exit 1
        }
    fi
done >&2
