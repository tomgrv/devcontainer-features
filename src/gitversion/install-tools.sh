#!/bin/sh
set -e

### Install GitVersion
echo "Install Gitversion..."
dotnet tool install GitVersion.Tool --version ${VERSION:-5.*} --tool-path /usr/local/bin

echo "Define Gitversion link..."
ln -sf /usr/local/bin/dotnet-gitversion /usr/local/bin/gitversion
