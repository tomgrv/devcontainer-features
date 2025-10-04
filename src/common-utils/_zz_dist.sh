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
		zz_log i "Found target in {U .zz_dist}: {B $config_target}"
		echo "$config_target"
		return 0
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

	return 1
}

# Determine the target directory
if [ -z "$target" ]; then
	# Try to get from config (first .zz_dist file, then package.json)
	if config_target=$(get_target_from_config); then
		target="$config_target"
	else
		# No target found in config
		if [ -n "$quiet" ]; then
			# Quiet mode: exit silently
			exit 0
		else
			# Error: no target specified
			zz_log e "No target directory specified. Use -t option, create .zz_dist file, or add config.zz_dist in package.json"
			exit 1
		fi
	fi
fi

# Resolve target to absolute path
target=$(readlink -f "$target")

# Verify target directory exists
if [ ! -d "$target" ]; then
	zz_log e "Target directory {U $target} does not exist"
	exit 1
fi

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

# Verify source directory exists
if [ ! -d "$source" ]; then
	zz_log e "Source directory {U $source} does not exist"
	exit 1
fi

zz_log i "Distributing zz_* utilities"
zz_log - "From: {U $source}"
zz_log - "To: {U $target}"



# Count utilities found and copied
count=0
copied=0

# Find and copy zz_* utilities
# Look for _zz_*.sh files in source directory
for file in "$source"/_zz_*.sh; do
	if [ -f "$file" ]; then
		count=$((count + 1))
		basename_file=$(basename "$file")
		dest_file="$target/$basename_file"

		# Copy the file
		cp "$file" "$dest_file"
		chmod +x "$dest_file"
		copied=$((copied + 1))
		zz_log s "Copied {B $basename_file}"
	fi
done

# Also look for zz_* symlinks/files (without underscore)
for file in "$source"/zz_*; do
	if [ -f "$file" ] || [ -L "$file" ]; then
		basename_file=$(basename "$file")
		# Skip if it's a symlink pointing to _zz_*.sh (already copied)
		if [ -L "$file" ]; then
			link_target=$(readlink "$file")
			if echo "$link_target" | grep -q "^.*/_zz_.*\.sh$"; then
				continue
			fi
		fi

		count=$((count + 1))
		dest_file="$target/$basename_file"

		# Copy the file (or link target)
		cp -L "$file" "$dest_file" 2>/dev/null || cp "$file" "$dest_file"
		chmod +x "$dest_file"
		copied=$((copied + 1))
		zz_log s "Copied {B $basename_file}"
	fi
done

if [ $copied -eq 0 ]; then
	zz_log w "No zz_* utilities found in {U $source}"
	exit 0
fi

zz_log s "Successfully distributed {B $copied} utilities to {U $target}"
