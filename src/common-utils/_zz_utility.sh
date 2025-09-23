#!/bin/sh
# Dispatcher utility used by scripts named with a leading underscore
# Example caller: src/gitutils/_git-fix.sh invokes: zz_utility $0 "$@"
# This script finds a counterpart script without the leading underscore
# in the same directory (or with .sh extension) and executes it.

set -e

# Source colors script for colored output
. zz_colors

# Parse arguments and display help if needed
eval $(
    zz_args "Dispatch Utility" $0 "$@" <<- help
		-   caller caller     Caller script path
        -   subcmd subcmd     Target script to execute
        +   params params     Remaining arguments passed to the target script
	help
)

# function to display usage information
usage() {
    zz_log i "Usage: ${name} <subcommand> [args...]" >&2
    if [ -d "${caller_dir}" ]; then
        zz_log - "Available utilities in ${caller_dir}:" >&2
        ls -1 "${caller_dir}" | grep -E "${name}(-.*)(\.sh)?$" | sed -e 's/^/_/' -e 's/^_\?//' | sed 's/^/    /' >&2 || true
    fi
}

# Determine caller directory and base name
caller_basename=$(basename "${caller}")
caller_dir=$(dirname "${caller}")

# Normalize name: remove leading underscore and extension
name=${caller_basename#_}
name=${name%.*}

# If no subcmd provided, show help and exit
if [ -z "${subcmd}" ]; then
    zz_log e "No subcommand provided." && usage $caller
    exit 1
fi



# If caller_dir is just the basename (no slash) and file exists in PATH, try to locate
if [ "${caller_dir}" = "${caller_basename}" ] || [ -z "${caller_dir}" ]; then
    caller_dir="."
fi

# Direct dispatch: map caller + subcommand to a single target
if [ -n "${subcmd}" ]; then
    target="${caller_dir}/${name}-${subcmd}"
else
    target="${caller_dir}/${name}"
fi

if [ -x "${target}" ]; then
    zz_log i "Dispatching to executable target: ${target}" >&2
    exec "${target}" $params
elif [ -f "${target}" ]; then
    zz_log i "Dispatching to subshell target: ${target}" >&2
    exec sh "${target}" $params
else
    # Nothing found: show help and available utilities in the same directory
    zz_log w "No dispatch target found" && usage
fi
