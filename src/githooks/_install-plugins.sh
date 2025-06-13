#!/bin/sh

json_key=$1
json_file=${2:-./package.json}

zz_log i "Using file {B $json_file}..."
plugins=$(jq -r "$1" "$json_file" | tr -d "'[]:,\"")

if [ -z "$plugins" ]; then
    zz_log w "No plugins found at key {B $json_key} in {U $json_file}"
    exit 0
fi

# Load the config file
config=$(dirname $0)/.ci-plugins

# foreach plugin, check if it is already installed
for plugin in $plugins; do

    if ! npm list $plugin 2>/dev/null 1>&2; then
        # Save the plugins to a config file
        zz_log i "Adding plugin {B $plugin} to list of CI dependencies ..."
        echo "$plugin" | sed 's/^ *//;s/ *$//' | grep -v --file=$config >>$config
    fi
done

# Reload the plugins list
plugins=$(cat $config | tr '\n' ' ')

# Install the plugins
zz_log i "Installing plugins {B $plugins} ..."
if ! npm install --no-save $plugins 2>/dev/null 1>&2; then
    zz_log e "Failed to install one of plugins {B $plugins}!"
    exit 1
fi

zz_log s "Plugins {B $plugins} installed successfully!"
