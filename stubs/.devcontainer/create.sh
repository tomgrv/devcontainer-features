#!/bin/sh

### Ensure correct access rights
sudo chown -Rf vscode ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*
sudo chmod -Rf 755 ${containerWorkspaceFolder:-.}/* ${containerWorkspaceFolder:-.}/.*

#### Create aliases
sudo cat <<EOF > ~/.bash_aliases
alias part='php artisan'
alias sart='sail artisan'
alias snpm='sail npm'
alias snpx='sail npx --yes'
alias spm2='sail npx --yes pm2'
alias smix='spm2 restart MixWatch'
alias smiw='spm2 --name MixWatch start npm -- run watch'
alias gitv='gitversion'
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
EOF
 