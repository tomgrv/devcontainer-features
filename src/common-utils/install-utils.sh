#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Resolve scripts from the tomgrv/scripts major this release was built against
### (same pin as common-utils), not main. Override with ZZ_ORIGIN_REF.
export ZZ_ORIGIN_REF="${ZZ_ORIGIN_REF:-v3}"

### Install utils (zz-use applies each tool's config check, e.g. mikefarah yq)
# shellcheck disable=SC2086
[ -z "$UTILS" ] || zz-use $UTILS >&2 || {
    zz-log w "Please install {B $UTILS} Manually."
    exit 1
}
