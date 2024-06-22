#!/bin/sh
set -e

### Define current script directory as hook directory
git config hooks.hookDir $(dirname $(readlink -f $0))
