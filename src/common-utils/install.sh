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

### Init directories
export source=$(dirname $(readlink -f $0))
export target=${1:-/usr/local/share}/$(basename $source | sed 's/_.*$//')

### Installs "install" scripts
find $source -name "_*.sh" -type f -exec cp {} $target \;

### Make a link to the script without the leading underscore and without the .sh extension
find $target -type f -name "_*.sh" -exec chmod +x {} \; -exec ln -s \$\(echo {} | sed -e 's/^_//' -e 's/\.sh$//'\) /usr/bin/ \;
