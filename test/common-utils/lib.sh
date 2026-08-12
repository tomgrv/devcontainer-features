#!/bin/sh
# Test setup for common-utils feature.
# Sources common test utilities and sets up feature-specific environment.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
. "$REPO_ROOT/test/lib.sh"

setup_feature_utils common-utils
