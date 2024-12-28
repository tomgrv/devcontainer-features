#!/bin/sh
set -e

workspace=${containerWorkspaceFolder:-${CODESPACE_VSCODE_FOLDER:-.}}
[ -f sail ] && echo sail || echo $workspace/vendor/bin/sail
