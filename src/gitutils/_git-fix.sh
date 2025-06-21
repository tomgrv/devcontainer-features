#!/bin/sh

# Function to print help and manage arguments
eval $(
	zz_args "Fix git utility" $0 "$@" <<-help
		- utils utils Utility to fix git commit messages
	help
)

# Check if the utils argument is provided
if [ -n "$utils" ]; then

	shift # Remove the first argument (utils)

	# Call the git-fix utility by injecting the utils name after 'git-fix' in $0, if it exists
	if [ -f "$(dirname "$0")/git-fix-$utils.sh" ]; then
		$(dirname "$0")/git-fix-$utils.sh "$@"

	# Call the git-fix utility by injecting the utils name after 'git-fix' in $0, if command exists
	elif command -v "git-fix-$utils" >/dev/null 2>&1; then
		git-fix-$utils "$@"
	else
		zz_log e "Utility 'git-fix-$utils' not found in $(dirname "$0")."
		exit 1
	fi
else
	zz_log e "No utils argument provided. Please specify a utility to fix git commit messages."
	zz_log i "Available utilities:"
	# List available git-fix utilities in the current directory with a tab in front of each utility
	ls -1 $(dirname "$0") | grep 'git-fix-' | sed 's/^_//g; s/\.sh$//g;s/^/\t/' | sort
fi
