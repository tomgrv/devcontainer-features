#!/bin/sh
set -e

### Init directories
export source=$(dirname $(readlink -f $0))
export feature=$(basename $source | sed 's/_.*$//')
export target=${1:-/usr/local/share}/$feature
echo "Activating feature <$feature>..."

#### Create aliases
sudo cat <<EOF > ~/.bash_aliases
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
 