#!/usr/bin/env bash
# Standard startup + baseline verification for this repo (harness init path).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "==> Working directory: $PWD"
echo "==> Syncing dependencies"
npm install --no-audit --no-fund

echo "==> Baseline verification (all bats suites)"
BATS=(bats)
command -v bats >/dev/null 2>&1 || BATS=(npx --yes bats)
suites=(tests)
for d in src/*/tests; do ls "$d"/*.bats >/dev/null 2>&1 && suites+=("$d"); done
"${BATS[@]}" "${suites[@]}"
