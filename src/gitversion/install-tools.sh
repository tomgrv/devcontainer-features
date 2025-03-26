#!/bin/sh
set -e

### Install GitVersion
zz_log i "Install Gitversion..."
dotnet tool install GitVersion.Tool --version ${VERSION:-5.*} --tool-path /usr/local/bin

zz_log i "Define Gitversion link..."
ln -sf /usr/local/bin/dotnet-gitversion /usr/local/bin/gitversion
