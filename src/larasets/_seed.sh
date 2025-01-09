#!/bin/sh
set -e

art key:generate --force
art config:cache
art view:cache
art route:cache
art event:cache
art optimize
art migrate --seed --graceful --no-interaction
