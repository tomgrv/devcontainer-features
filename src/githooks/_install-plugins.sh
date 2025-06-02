#!/bin/sh

json_key=$1
json_file=${2:-package.json}

plugins=$(cat $json_file | npx --yes jqn "$1" | tr -d "'[]:,\"")

if [ -z "$plugins" ]; then
    zz_log w "No plugins found at key {B $json_key} in {U $json_file}"
elif ! npm list $plugins 2>/dev/null 1>&2; then

    config=$(dirname $0)/.ci-plugins

    # Save the plugins to a config file
    zz_log i "Adding plugins {B $plugins} to list of CI dependencies ..."
    echo "$plugins" | sed 's/^ *//;s/ *$//' | grep -v --file=$config >>$config

    # Reload the plugins list
    plugins=$(cat $config | tr '\n' ' ')

    # Install the plugins
    zz_log i "Installing plugins {B $plugins} ..."
    npm install --no-save $plugins 2>/dev/null 1>&2
    zz_log s "Plugins {B $plugins} installed successfully!"
fi
