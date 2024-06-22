#!/bin/sh
export PATH=/usr/bin:$PATH

# Enable colors
if [ -t 1 ]; then
  exec >/dev/tty 2>&1
fi

# Check if file is changed
isChanged() {
  git diff --name-only HEAD@{1} HEAD | grep "^$1" >/dev/null 2>&1
}

# Checkout composer.lock or package-lock.json if changed
if isChanged 'composer.lock' || isChanged 'package-lock.json'; then
  git checkout --theirs composer.lock package-lock.json && git add composer.lock package-lock.json
  npx chalk-cli --no-stdin -t "{green.bold Files <package-lock.json> or <composer.lock> changed.}"
  npx chalk-cli --no-stdin -t "{green.bold Run composer/npm install to bring your dependencies up to date.}"
fi
