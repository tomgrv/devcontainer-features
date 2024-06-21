#!/bin/sh
set -e

echo "Activating feature 'giversion ${VERSION}'"

### Install GitVersion
dotnet tool install --global GitVersion.Tool --version ${VERSION}
sudo ln -s ~/.dotnet/tools/dotnet-gitversion /usr/bin/gitversion
