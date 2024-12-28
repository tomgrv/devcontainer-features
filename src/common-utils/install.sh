#!/bin/sh
set -e

### Options
UTILS="${UTILS:-"jq dos2unix"}"

### Install utils
for bin in $UTILS; do
	if [ -n "$(command -v $bin)" ]; then
		echo "$bin is installed."
	elif [ -f /etc/alpine-release ]; then
		apk update
		apk add $bin
	elif [ $(uname) = "Linux" ] || [ $(uname) = "Darwin" ]; then
		sudo apt-get update
		sudo apt-get install -y $bin
	else
		echo "Please install $bin."
		exit 1
	fi
done

### Install this feature
$(dirname $0)/_install-feature.sh
$(dirname $0)/_install-bin.sh
