#!/bin/sh

# Manage arguments
eval $(
    zz_args "Export Source/Targets folders depending on feature context" $0 "$@" <<-help
        s source 	source		Force source directory
        t target	target		Force target directory
        - caller	caller		Force caller script
help
)

# If the source directory is set, resolve the full path
if [ -n "$source" ]; then
    source=$(readlink -f $source)

# If the source directory is not set, initialize it based on the caller script
else

    if [ -z "$caller" ]; then

        # Determine the caller script, remove /bin/xxx from the beginning of the command line and empty lines
        caller=$(readlink -f $PWD/$(tr '\0' '\n' </proc/$PPID/cmdline | sed 's/^\/bin\/.*$//' | grep -v '^$' | head -n 1))
        zz_log - "Caller script is {U $caller}"

        # If the caller script cannot be determined, exit with an error
        if [ -z "$caller" ]; then
            zz_log e "Not in script context" && exit 1
        fi

    fi

    # Set the source directory to the directory of the caller script if not already set. Remove trailing . or / from the path
    source=$(readlink -f $(dirname $caller))
fi

# Set the feature name based name of the source directory, remove last _number if present
feature=$(basename $source | sed 's/_[0-9]*$//')

# If the target directory is not set, initialize it based on the feature name
if [ -z "$target" ]; then

    if [ -w /usr/local/share ]; then
        target=/usr/local/share/$feature
    elif [ -w /tmp ]; then
        target=/tmp/$feature
    else
        zz_log e "No writeable directory found" && exit 1
    fi
fi

# Create the target directory if it does not exist
mkdir -p $target

# Log the results
zz_log s "Selected context for {Purple $feature} is {U $source} => {U $target}"

# Results
echo source=$source
echo feature=$feature
echo target=$target
