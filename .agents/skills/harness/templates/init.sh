#!/usr/bin/env bash
# Standard startup + baseline verification. Adapt the three commands to the repo.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

INSTALL_CMD=(npm install)
VERIFY_CMD=(npm test)
START_CMD=(npm run dev)

echo "==> Working directory: $PWD"
echo "==> Syncing dependencies"
"${INSTALL_CMD[@]}"

echo "==> Running baseline verification"
"${VERIFY_CMD[@]}"

echo "==> Startup command: ${START_CMD[*]}"
if [ "${RUN_START_COMMAND:-0}" = "1" ]; then
    exec "${START_CMD[@]}"
fi
echo "Set RUN_START_COMMAND=1 to launch the app from this script."
