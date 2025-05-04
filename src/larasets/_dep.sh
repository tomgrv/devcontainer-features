#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Run deployer with secrets
secret $HOME/.composer/vendor/bin/dep "$@"
