#!/bin/sh

# Function to print help and manage arguments

eval $(
    zz_args "Install npm plugins from package.json configuration" $0 "$@" <<-help
        f file      json_file   Package.json file path (default: ./package.json)
        - key       json_key    JSON key path to extract plugins from
help
)

# Set defaults if not provided
json_file=${json_file:-./package.json}

if [ -z "$json_key" ]; then
    zz_log e "JSON key is required."
    exit 1
fi

zz_log i "Using file {B $json_file}..."
plugins=$(jq -r "$json_key" "$json_file" | tr -d "'[]:,\"")

if [ -z "$plugins" ]; then
    zz_log w "No plugins found at key {B $json_key} in {U $json_file}"
    exit 0
fi

# Load the config file
config=$(dirname $0)/.ci-plugins

# if config file only contains comments and empty lines, make it empty
if [ -f "$config" ] && [ -z "$(grep -v -e '^#' -e '^$' $config)" ]; then
    zz_log w "Config file {B $config} is empty or contains only comments, reset it."
    cat /dev/null >$config
fi  

# Create the config file if it doesn't exist
if [ ! -f "$config" ]; then
    zz_log w "Config file {B $config} does not exist, create it."
    touch $config
fi

# foreach plugin, check if it is already installed
for plugin in $plugins; do
    echo "$plugin" | sed 's/^ *//;s/ *$//' | grep -v --file=$config >>$config
done

# Reload the plugins list
plugins=$(cat $config | grep -v '^$' | tr '\n' ' ')

# For each plugin, check if it is already installed
for plugin in $plugins; do
    if npm list --depth=0 | grep -q "$plugin@"; then
        plugins=$(echo $plugins | sed "s#$plugin##g" | tr -s ' ')
    fi
done

# Install the plugins if there are any to install
if [ -n "$plugins" ]; then
    zz_log i "Installing plugins {B $plugins} ..."
    if ! npm install --no-save $plugins 2>/dev/null 1>&2; then
        zz_log e "Failed to install one of plugins {B $plugins}!"
        exit 1
    fi
    zz_log s "Plugins {B $plugins} installed successfully!"
fi