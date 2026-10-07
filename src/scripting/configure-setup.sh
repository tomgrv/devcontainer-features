#!/bin/sh

### Ensure the repo's root setup.sh exists and matches the standard
### zz-use-bootstrap template (stubs/setup.sh) - deploy/repair it if it's
### missing or has drifted, so every start leaves the repo with a working,
### up-to-date entrypoint.
if [ -z "${source:-}" ]; then
    zz-log e "scripting: \$source not set (expected to be exported by feature-configure)."
    exit 1
fi
canonical="$source/stubs/setup.sh"

if [ -f setup.sh ] && cmp -s setup.sh "$canonical"; then
    zz-log s "setup.sh already matches the standard."
else
    if [ -f setup.sh ]; then
        zz-log w "setup.sh differs from the standard - restoring it."
    else
        zz-log i "setup.sh missing - deploying the standard."
    fi
    cp "$canonical" setup.sh
    chmod +x setup.sh
    zz-log s "setup.sh deployed."
fi
