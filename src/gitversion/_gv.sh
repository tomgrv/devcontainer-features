#!/bin/sh

# Call the GitVersion tool with the specified configuration
/usr/local/bin/dotnet-gitversion  $(git rev-parse --show-toplevel)  -config ".gitversion" "$@"

