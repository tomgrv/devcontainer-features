#!/bin/sh

# Provision VS Code extensions from VSIX, in parallel with VS Code attaching.
#
# Detaches 'gateway-vsix sync' so container creation never waits on it: it
# fetches (with curl) whatever devcontainer.json lists and the image build
# didn't already pre-fetch, waits for the VS Code server to show up, then
# installs every cached VSIX with the server's own CLI.
#
# Sorted after configure-certs.sh by configure-feature, so the root CA is
# already trusted when the downloads start. Container-only: on a host there's
# no VS Code server to wait for.

. zz-colors

if [ ! -f /.dockerenv ] && [ -z "${REMOTE_CONTAINERS:-}" ] && [ "${CODESPACES:-}" != "true" ]; then
    exit 0
fi

if ! command -v gateway-vsix >/dev/null 2>&1; then
    zz-log w "gateway-vsix not found on PATH, VS Code extensions left to VS Code itself"
    exit 0
fi

logfile="${TMPDIR:-/tmp}/gateway-vsix.log"
detach=""
command -v setsid >/dev/null 2>&1 && detach=setsid

nohup $detach gateway-vsix sync >"$logfile" 2>&1 </dev/null &
zz-log s "VS Code extensions provisioning started in background, log at {U $logfile}"
