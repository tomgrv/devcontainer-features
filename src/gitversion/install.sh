#!/bin/sh
set -e

echo "Activating feature 'giversion ${VERSION}'"

### Install GitVersion
dotnet tool install GitVersion.Tool --version ${VERSION} --tool-path /usr/local/bin
sudo ln -s /usr/local/bin/dotnet-gitversion /usr/local/bin/gitversion


