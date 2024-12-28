#!/bin/sh
set -e

workspace=${containerWorkspaceFolder:-${CODESPACE_VSCODE_FOLDER:-.}}
sh $([ -f "sail" ] && echo sail || [ -f "$workspace/vendor/bin/sail" ] && echo $workspace/vendor/bin/sail) "$@"
