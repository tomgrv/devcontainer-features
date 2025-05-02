#!/bin/sh

set -e

# Source colors script
. zz_colors

# Function to print help and manage arguments
eval $(
    zz_args "Run act with predefined arguments" $0 "$@" <<-help
	help
)

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

for e in "SSH_KNOWN_HOSTS<ssh-keyscan -H ${KNOWN_HOST}" "SSH_PRIVATE_KEY" "SSH_CONFIG"; do

    # extract the alias name from the first part of the string
    # and the underlying value from the second part
    a=$(echo "$e" | cut -d'<' -f1)
    v=$(echo "$e" | cut -d'<' -f2 -s)

    # Set alias name to the value of the underlying variable
    if [ -n "$v" ]; then
        zz_log i "Setting <{B $a}>..."
        eval export $a="\$($v)"
    fi

    # Build the argument to pass to act
    if [ -n "$(eval echo "\$$a")" ]; then
        zz_log i "Passing <{B $a}>..."
        ARGS="$ARGS --secret $a"
    fi

done

echo act --artifact-server-path ./.artifacts $ARGS "$@"

#### Back to previous directory
cd - >/dev/null
