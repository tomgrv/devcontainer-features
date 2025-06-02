#!/bin/sh

json_key=$1
json_file=${2:-package.json}

plugins=$(cat $json_file | npx --yes jqn "$1" | tr -d "'[]:,\"\n")

if [ -z "$plugins" ]; then
    zz_log w "No plugins found at key {B $json_key} in {U $json_file}"
elif ! npm list $plugins 2>/dev/null 1>&2; then
    zz_log i "Installing plugins {B $plugins} ..."
    npm install --no-save $plugins 2>/dev/null 1>&2
    zz_log s "Plugins {B $plugins} installed successfully!"
fi
