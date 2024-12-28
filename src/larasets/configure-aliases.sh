#!/bin/sh
set -e

#### Do not use sudo if on mingw
if [ $(uname) = "Linux" ] || [ $(uname) = "Darwin" ]; then
    SUDO=sudo
else
    SUDO=
fi

#### Create aliases
$SUDO cat <<EOF >~/.bash_aliases

alias gitv='gitversion'

log() {
    srv logs server_\$1
} && export -f log

refresh() {
    art config:cache
    art view:cache
    art route:cache
    art optimize:clear
} && export -f refresh

init() {
    test -f \${CODESPACE_VSCODE_FOLDER:-.}/artisan || return 1
    test -n "\$LARAVEL_SAIL" && test "\$LARAVEL_SAIL" -eq 1 && sail up --build -d
    art key:generate --force
    refresh
    art migrate --graceful --no-interaction
    run dev
} && export -f init

EOF
