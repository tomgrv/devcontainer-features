#!/bin/sh
set -e

### Install GitVersion
echo "Install Gitversion..."
dotnet tool install GitVersion.Tool --version ${VERSION} --tool-path /usr/local/bin

echo "Define Gitversion link..."
ln -s /usr/local/bin/dotnet-gitversion /usr/local/bin/gitversion
