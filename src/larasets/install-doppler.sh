#!/bin/sh

### Persist option-driven environment for interactive shells
### (DOPPLER_CONFIG is per-consumer, so it comes from the `doppler` option,
###  never a hardcoded value)
if [ -n "${DOPPLER:-}" ]; then
    profile=/etc/profile.d/larasets-doppler.sh
    if mkdir -p /etc/profile.d 2>/dev/null && touch "$profile" 2>/dev/null; then
        echo "export DOPPLER_CONFIG=${DOPPLER}" >>"$profile"
    fi
fi
