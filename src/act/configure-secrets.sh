#!/bin/sh

echo "SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa | tr -d '\n')" >>.github/workflows/.secrets
