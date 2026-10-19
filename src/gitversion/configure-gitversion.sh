#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Get GitVersion: Docker image, else dotnet tool
if docker info >/dev/null 2>&1; then
    zz-log i "Pull Gitversion Docker image..."
    docker pull gittools/gitversion:${VERSION:-6.5.1}
elif command -v dotnet >/dev/null 2>&1; then
    zz-log w "docker unavailable, installing Gitversion dotnet tool..."
    dotnet tool install --global GitVersion.Tool --version ${VERSION:-6.5.1} \
        || dotnet tool update --global GitVersion.Tool --version ${VERSION:-6.5.1}
else
    zz-log e "Neither a working docker nor dotnet found, cannot provide Gitversion"
    exit 1
fi
