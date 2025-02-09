#!/bin/sh

##### HELP #####
. $(dirname $0)/_zz-args.sh "Export Source/Targets folders depending on feature context" $0 $@ <<-help
	s source 	source		Force source directory
    t target	target		Force target directory
help

if [ -z "$source" ]; then

    ### Init directories
    if [ "$(uname -o)" = "Msys" ]; then
        caller=$(tr -d '\0' </proc/$PPID/cmdline | sed 's/ .*$//' | sed 's|.*/||')
    else
        caller=$(ps -o args= $PPID)
    fi

    caller=$(readlink -f ${caller##/bin/sh})

    if [ -z "$caller" ]; then
        echo "Not in script context" | npx --yes chalk-cli --stdin red
        exit 1
    fi

    declare -x source=${source:-$(dirname $caller)}
fi

declare -x feature=$(basename $source | sed 's/_.*$//')

if [ -z "$target" ]; then
    declare -x target=${target:-/usr/local/share/$feature}
fi

### Create target directory
mkdir -p $target
