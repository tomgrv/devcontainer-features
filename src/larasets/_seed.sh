#!/bin/sh
set -e

art key:generate --force
art migrate --seed --graceful --no-interaction
art config:cache
art view:cache
art route:cache
art event:cache
art optimize:clear
