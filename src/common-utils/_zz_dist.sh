#!/bin/sh

set -e

# Source colors script
. zz_colors

# Parse arguments and display help if needed
eval $(
	zz_args "Distribute zz_* utilities to target directory" $0 "$@" <<-help
		t target    target       Target directory (required unless specified in config)
		s source    source       Source directory (default: /usr/local/share/common-utils)
		q -         quiet        Quiet mode: exit 0 if no target found instead of error
	help
)

# Function to read target from config
get_target_from_config() {
	local config_target=""

	# Check for .zz_dist file in project root
	if [ -f ".zz_dist" ]; then
		config_target=$(cat .zz_dist | head -n 1 | tr -d '\r\n ')
		if [ -n "$config_target" ]; then
			zz_log i "Found target in {U .zz_dist}: {B $config_target}"
			echo "$config_target"
			return 0
		fi
	fi

	# Check for config.zz_dist in package.json using zz_json
	if [ -f "package.json" ]; then
		config_target=$(zz_json package.json 2>/dev/null | jq -r '.config.zz_dist // empty' 2>/dev/null)
		if [ -n "$config_target" ]; then
			zz_log i "Found target in {U package.json}: {B $config_target}"
			echo "$config_target"
			return 0
		fi
	fi
}

# Determine the target directory
if [ -z "$target" ]; then
	# Try to get from config (first .zz_dist file, then package.json)
	target=$(get_target_from_config);
	if [ -z "$target" ] && [ -n "$quiet" ]; then
		# Quiet mode: exit 0 if no target found
		zz_log w "No target directory specified. Exiting quietly."
		exit 0
	elif [ -z "$target" ]; then
		# No target found: error out
		zz_log e "No target directory specified. Use -t option, create .zz_dist file, or add config.zz_dist in package.json"
		exit 1
	fi
fi

# Resolve target to absolute path
target=$(readlink -f "$target")

# Verify target directory exists
if [ ! -d "$target" ]; then
	zz_log e "Target directory {U $target} does not exist"
	exit 1
fi

zz_log s "Resolved target directory to {U $target}"

# Set default source directory
if [ -z "$source" ]; then
	# Try common installation locations
	if [ -d "/usr/local/share/common-utils" ]; then
		source="/usr/local/share/common-utils"
	elif [ -d "/usr/local/bin" ]; then
		source="/usr/local/bin"
	else
		zz_log e "No source directory found. Expected /usr/local/share/common-utils or /usr/local/bin"
		exit 1
	fi
fi

zz_log i "Distributing zz_* utilities"
zz_log - "From: {U $source}"
zz_log - "To: {U $target}"


# Copy zz_* files from source to target
for file in $(ls -1 $source/*zz_*); do

	zz_log - "Processing file: {U $file}"

	# _zz_*.sh files are copied as zz_* files without leading underscore and .sh extension
	if [ -f "$file" ] || [ -L "$file" ]; then
		basefile=$(basename "$file")
		if echo "$basefile" | grep -q '^_zz_.*\.sh$'; then
			targetfile=$target/$(echo "$basefile" | sed -e 's/^_//;s/\.sh$//')
		else
			targetfile=$target/$basefile
		fi

		# Copy file if it exists and is executable
		if [ -x "$file" ]; then
			cp -u "$file" "$targetfile"
			chmod +x "$targetfile"
			zz_log s "Copied {U $basefile} to {U $targetfile}"
		else
			zz_log w "Skipping non-executable file {U $basefile}"
		fi
	fi
done

zz_log s "Successfully distributed utilities to {U $target}"
