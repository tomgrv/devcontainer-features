#!/bin/sh

### Ensure the repo's root setup.sh exists and matches the standard
### zz_use-bootstrap template (stubs/setup.sh) - deploy/repair it if it's
### missing or has drifted, so every start leaves the repo with a working,
### up-to-date entrypoint.
canonical="$source/stubs/setup.sh"

if [ -f setup.sh ] && cmp -s setup.sh "$canonical"; then
    zz_log s "setup.sh already matches the standard."
else
    if [ -f setup.sh ]; then
        zz_log w "setup.sh differs from the standard - restoring it."
    else
        zz_log i "setup.sh missing - deploying the standard."
    fi
    cp "$canonical" setup.sh
    chmod +x setup.sh
    zz_log s "setup.sh deployed."
fi
