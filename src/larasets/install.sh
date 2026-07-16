#!/bin/sh

### Install this feature
install-feature $0
install-bin $0

### Persist option-driven environment for interactive shells
### (DOPPLER_CONFIG is per-consumer, so it comes from the `doppler` option,
###  never a hardcoded value)
if [ -n "${DOPPLER:-}" ]; then
    profile=/etc/profile.d/larasets.sh
    if mkdir -p /etc/profile.d 2>/dev/null && touch "$profile" 2>/dev/null; then
        echo "export DOPPLER_CONFIG=${DOPPLER}" >>"$profile"
    fi
fi
