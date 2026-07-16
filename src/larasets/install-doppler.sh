#!/bin/sh

### Persist option-driven environment for interactive shells
### (DOPPLER_CONFIG is per-consumer, so it comes from the `doppler` option,
###  never a hardcoded value)
if [ -n "${DOPPLER:-}" ]; then
    zz_persist -p larasets-doppler DOPPLER_CONFIG "${DOPPLER}"
fi
