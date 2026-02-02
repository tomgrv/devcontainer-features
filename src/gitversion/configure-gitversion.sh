#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Get Docker GitVersion image
zz_log i "Pull Gitversion Docker image..."
docker pull gittools/gitversion:${VERSION:-6.5.1} 