#!/bin/sh

# Ensure the git-flow extension is installed on the system.
git flow version >/dev/null 2>&1 && exit 0

zz_log w "git-flow is not installed. Attempting installation..."

# Escalate only when needed and possible
asroot=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    asroot="sudo"
fi

if command -v apt-get >/dev/null 2>&1; then
    $asroot apt-get update && $asroot apt-get install -y git-flow
elif command -v apk >/dev/null 2>&1; then
    $asroot apk add --no-cache gitflow-avh
elif command -v dnf >/dev/null 2>&1; then
    $asroot dnf install -y gitflow
elif command -v yum >/dev/null 2>&1; then
    $asroot yum install -y gitflow
elif command -v brew >/dev/null 2>&1; then
    brew install git-flow-avh
elif command -v pacman >/dev/null 2>&1; then
    $asroot pacman -S --noconfirm gitflow-avh
elif command -v zypper >/dev/null 2>&1; then
    $asroot zypper --non-interactive install git-flow
else
    zz_log e "Unable to install git-flow automatically on this system."
    zz_log - "Please install it manually."
    exit 1
fi

if ! git flow version >/dev/null 2>&1; then
    zz_log e "git-flow is still unavailable after installation attempt."
    exit 1
fi
zz_log s "git-flow installed successfully."
