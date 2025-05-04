#!/bin/sh
set -e

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

#### Execute command
sh $([ -f "sail" ] && echo sail || [ -f "./vendor/bin/sail" ] && echo ./vendor/bin/sail) "$@"
