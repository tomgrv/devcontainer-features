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
alias art='php artisan'
alias pm2='npx --yes pm2'
alias dev='pm2 restart devserver || pm2 --name devserver start npm -- run dev'
alias sart='sail artisan'
alias snpm='sail npm'
alias snpx='sail npx --yes'
alias spm2='sail npx --yes pm2'
alias sdev='spm2 restart devserver || spm2 --name devserver start npm -- run dev'
alias gitv='gitversion'
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
EOF
