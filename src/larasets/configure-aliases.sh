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
alias sail='sh $([ -f sail ] && echo sail || echo ${containerWorkspaceFolder:-.}/vendor/bin/sail)'

art() {
    test -n "\$LARAVEL_SAIL" && test "\$LARAVEL_SAIL" -eq 1 && sail artisan "\$@" || php -d xdebug.mode=off \${CODESPACE_VSCODE_FOLDER:-.}/artisan "\$@"
} && export -f art

srv() {
    test -n "\$LARAVEL_SAIL" && test "\$LARAVEL_SAIL" -eq 1 && sail npx --yes pm2 "\$@" || npx --yes pm2 "\$@"
} && export -f srv

run() {
    srv restart server_\$1 || srv --name server_\$1 start npm -- run \$1
} && export -f run

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
