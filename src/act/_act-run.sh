#!/bin/sh

set -e

# Source colors script for colored output
. zz_colors

# Parse arguments and display help if needed
eval $(
    zz_args "Run act with predefined arguments" $0 "$@" <<-help
	help
)

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Loop through predefined environment variables
for e in "KNOWN_HOSTS" "SSH_PRIVATE_KEY" "SSH_CONFIG"; do

    # Extract the alias name (before '<') and the underlying value (after '<')
    a=$(echo "$e" | cut -d'<' -f1)
    v=$(echo "$e" | cut -d'<' -f2 -s)

    # Set the alias name to the value of the underlying variable if it exists
    if [ -n "$v" ]; then
        zz_log i "Setting <{B $a}>..."
        eval export $a="\$($v)"
    fi

    # Build the argument to pass to act if the alias has a value
    if [ -n "$(eval echo "\$$a")" ]; then
        zz_log i "Passing <{B $a}>..."
        ARGS="$ARGS --secret $a"
    fi

done

# Run the act command with the constructed arguments
act --artifact-server-path ./.artifacts $ARGS "$@"
