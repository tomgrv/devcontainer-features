#!/bin/sh

set -e

# Get the directory of the script
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Source colors script for colored output
if [ -f "$script_dir/_zz_colors.sh" ]; then
	. "$script_dir/_zz_colors.sh"
elif command -v zz_colors >/dev/null 2>&1; then
	. zz_colors
else
	# Fallback: define basic color variables if colors script is not found
	End=''
	Red=''
	Green=''
	Yellow=''
	Blue=''
	Purple=''
	White=''
fi

# Source args script for argument parsing
if [ -f "$script_dir/_zz_args.sh" ]; then
	zz_args="$script_dir/_zz_args.sh"
elif command -v zz_args >/dev/null 2>&1; then
	zz_args="zz_args"
else
	echo "Error: zz_args script not found" >&2
	exit 1
fi

# Parse arguments and display help if needed
eval $(
	$zz_args "Distribute zz_* utilities to target directory" $0 "$@" <<-help
		t target    target       Target directory (default: current directory or from config)
		s source    source       Source directory (default: /usr/local/share/common-utils)
	help
)

# Source log script for logging
if [ -f "$script_dir/_zz_log.sh" ]; then
	zz_log="$script_dir/_zz_log.sh"
elif command -v zz_log >/dev/null 2>&1; then
	zz_log="zz_log"
else
	# Fallback: define basic log function
	zz_log() {
		level="$1"
		shift
		echo "[$level] $*" >&2
	}
fi

# Function to read target from config
get_target_from_config() {
	local config_target=""

	# Check for .zz_dist file in project root
	if [ -f ".zz_dist" ]; then
		config_target=$(cat .zz_dist | head -n 1 | tr -d '\r\n ')
		$zz_log i "Found target in {U .zz_dist}: {B $config_target}"
		echo "$config_target"
		return 0
	fi

	# Check for config.zz_dist in package.json
	if [ -f "package.json" ] && command -v jq >/dev/null 2>&1; then
		config_target=$(jq -r '.config.zz_dist // empty' package.json 2>/dev/null)
		if [ -n "$config_target" ]; then
			$zz_log i "Found target in {U package.json}: {B $config_target}"
			echo "$config_target"
			return 0
		fi
	fi

	return 1
}

# Determine the target directory
if [ -z "$target" ]; then
	# Try to get from config
	if config_target=$(get_target_from_config); then
		target="$config_target"
	else
		# Default to current directory
		target="."
		$zz_log i "Using default target: {B $target}"
	fi
fi

# Resolve target to absolute path
target=$(readlink -f "$target")

# Set default source directory
if [ -z "$source" ]; then
	# Try common installation locations
	if [ -d "/usr/local/share/common-utils" ]; then
		source="/usr/local/share/common-utils"
	elif [ -d "/usr/local/bin" ]; then
		source="/usr/local/bin"
	else
		$zz_log e "No source directory found. Expected /usr/local/share/common-utils or /usr/local/bin"
		exit 1
	fi
fi

# Verify source directory exists
if [ ! -d "$source" ]; then
	$zz_log e "Source directory {U $source} does not exist"
	exit 1
fi

$zz_log i "Distributing zz_* utilities"
$zz_log - "From: {U $source}"
$zz_log - "To: {U $target}"

# Create target directory if it doesn't exist
if [ ! -d "$target" ]; then
	$zz_log i "Creating target directory {U $target}"
	mkdir -p "$target"
fi

# Count utilities found and copied
count=0
copied=0

# Find and copy zz_* utilities
if [ -d "$source" ]; then
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
			$zz_log s "Copied {B $basename_file}"
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
			$zz_log s "Copied {B $basename_file}"
		fi
	done
fi

if [ $copied -eq 0 ]; then
	$zz_log w "No zz_* utilities found in {U $source}"
	exit 0
fi

$zz_log s "Successfully distributed {B $copied} utilities to {U $target}"
