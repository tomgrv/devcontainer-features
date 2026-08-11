#!/bin/sh

#### Goto repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

### Set permissions and ownership for workspace files
zz_log i "Setting id_rsa if not exists"
if [ -z \"$CODESPACES\" ]; then
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    fi
    zz_log s "Your public key is:"
    cat ~/.ssh/id_rsa.pub
fi
