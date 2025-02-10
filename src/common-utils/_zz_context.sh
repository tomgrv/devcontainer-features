#!/bin/sh

# Source the argument parsing script to handle input arguments

eval $(
    zz_args "Export Source/Targets folders depending on feature context" $0 "$@" <<-help
        s source 	source		Force source directory
        t target	target		Force target directory
        - caller	caller		Force caller script
help
)

# If the source directory is not set, initialize it based on the script context
if [ -z "$caller" ]; then

    # Determine the caller script
    if [ "$(uname -o)" = "Msys" ]; then
        caller=$(tr '\0' '\n' </proc/$PPID/cmdline | head -n 1)
    else
        caller=$(ps -o args= $PPID)
    fi

    echo "Caller script is <$caller>" >&2
    caller=$(readlink -f ${caller##/bin/sh})

    # If the caller script cannot be determined, exit with an error
    if [ -z "$caller" ]; then
        echo "Not in script context" | npx --yes chalk-cli --stdin red
        exit 1
    fi
fi

# Set the source directory to the directory of the caller script
source=${source:-$(dirname $caller)}

# Set the feature name based on the source directory
feature=$(basename $source | sed 's/_.*$//')

# If the target directory is not set, initialize it based on the feature name
if [ -z "$target" ]; then

    if [ -w /usr/local/share ]; then
        target=${target:-/usr/local/share/$feature}
    elif [ -w /tmp ]; then
        target=${target:-/tmp/$feature}
    else
        echo "No writeable directory found" >&2
        exit 1
    fi

fi

# Create the target directory if it does not exist
mkdir -p $target

# Log the results
echo "Selected context for <$feature> is '$source' => '$target'" >&2

# Results
echo source=$source
echo feature=$feature
echo target=$target
