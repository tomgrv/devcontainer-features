#!/bin/sh

set -e

# Source colors script for colored output
. zz_colors

# Parse arguments and display help if needed
eval $(
	zz_args "Allow script editing" $0 "$@" <<-help
		- script    script       script to edit
	help
)

# Check if the specified script exists in the /usr/local/bin directory
if [ ! -f "/usr/local/bin/$script" ]; then
	echo "Script $script is not defined in /usr/local/bin."
	exit 1
fi

# Copy the script to the current directory and make it executable
cp /usr/local/bin/$script ./$script
chmod +x ./$script

# Open the script in the default code editor
code ./$script

# Log a message indicating the script has been copied and opened
zz_log i "Script {Purple $script} copied to current directory and opened in code editor."
