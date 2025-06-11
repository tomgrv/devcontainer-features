#!/bin/sh

# Call the GitVersion tool with the specified configuration
/usr/local/bin/dotnet-gitversion -config ${1:-$(git rev-parse --show-toplevel)/.gitversion}
