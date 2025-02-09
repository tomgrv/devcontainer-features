#!/bin/sh

### Options
UTILS="${UTILS:-"jq dos2unix"}"

### Install utils
for bin in $UTILS; do

	echo "Checking $bin..." >&2

	if [ -n "$(command -v $bin)" ]; then
		echo "$bin is installed."
	elif [ -f /etc/alpine-release ]; then
		apk update
		apk add $bin
	elif [ $(uname) = "Linux" ] || [ $(uname) = "Darwin" ]; then
		sudo apt-get update
		sudo apt-get install -y $bin
	elif [ $(uname -o) = "Msys" ]; then
		winget install -s winget -e --name $bin --location /tmp/common-utils
	else
		echo "Please install $bin."
		exit 1
	fi
done

# Install the feature
. $(dirname $0)/_install-bin.sh -s $PWD/$(dirname $0)
. $(dirname $0)/_install-feature.sh -s $PWD/$(dirname $0)
