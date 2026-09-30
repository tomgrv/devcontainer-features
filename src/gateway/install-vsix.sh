#!/bin/sh

# Pre-fetch the VS Code extensions listed in the "vsix" feature option into the
# image, with curl, during the docker build itself — so the VS Code server
# never has to download them with its own Node.js http stack, which cannot get
# past the SSL inspection gateway's interception form.
#
# The gateway-curl wrapper is called by path, not through the (possibly not
# yet) diverted system curl, as install-*.sh scripts run in no fixed order.
#
# Download failures are not fatal: 'configure-feature gateway' (configure-vsix.sh)
# retries whatever devcontainer.json lists at container creation, once the
# root CA is trusted.

. zz_colors

eval $(
    zz_context "$@"
)

list=$(echo "${VSIX:-}" | tr ',' ' ')
[ -n "$(echo "$list" | tr -d ' ')" ] || exit 0

wrapper="$target/stubs/.devcontainer/.gateway/gateway-curl.sh"
[ -f "$wrapper" ] && export GATEWAY_VSIX_CURL="$wrapper"

dest="$target/vsix"
zz_log i "Pre-fetching VS Code extensions into {U $dest}..."
# shellcheck disable=SC2086 # one argument per extension id
if sh "$target/bin/gateway-vsix.sh" fetch "$dest" $list; then
    zz_log s "VS Code extensions pre-fetched"
else
    zz_log w "Some VS Code extensions could not be pre-fetched, retried at container creation"
fi
chmod -R a+rX "$dest" 2>/dev/null
exit 0
