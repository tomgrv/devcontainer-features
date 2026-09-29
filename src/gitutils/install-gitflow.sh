#!/bin/sh

# Ensure the git-flow extension is installed on the system.
git flow version >/dev/null 2>&1 && exit 0

zz_log w "git-flow is not installed. Attempting installation..."

zz_use zz_install
zz_install git-flow apk=gitflow-avh dnf=gitflow yum=gitflow \
    brew=git-flow-avh pacman=gitflow-avh || {
    zz_log e "Unable to install git-flow automatically on this system."
    zz_log - "Please install it manually."
    exit 1
}

if ! git flow version >/dev/null 2>&1; then
    zz_log e "git-flow is still unavailable after installation attempt."
    exit 1
fi
zz_log s "git-flow installed successfully."
