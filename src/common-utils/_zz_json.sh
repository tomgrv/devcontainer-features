#!/bin/sh
set -e

# Source colors script
. zz_colors

# Manage arguments
eval $(
    zz_args "Load json from specified source" $0 "$@" <<-help
        s -           schema		JSON is a schema
        - source      source		JSON file to load
help
)

# if schema is a url, download it
if test -n "$(echo $source | grep -E '^http')"; then
    zz_log i "Downloading file from {U $source}"
    curl -s $source
    if [ $? -ne 0 ]; then
        zz_log e "Unable to download file {U $source}" && exit 1
    fi
elif test -f "$source"; then
    zz_log i "Loading file {U $source}"
    cat $source
else
    zz_log e "File {U $source} not found" && exit 1
fi | sed -e 's:^[[:blank:]]*//.*$::g' 2>/dev/null | jq --arg source "$source" --arg schema "${schema:+true}" 'if . == null then {} else . end | if ($source != "" and has("$id")) or $schema == "" then . else . + {"$id": $source} end'
