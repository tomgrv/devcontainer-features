#!/bin/sh

# Ensure git-flow is available before dispatching any release subcommand.

if ! git flow version >/dev/null 2>&1; then
	
    zz_log w "git-flow is not installed. Attempting installation..."
    if command -v apt-get >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            apt-get update && apt-get install -y git-flow
        elif command -v sudo >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y git-flow
        else
            apt-get update && apt-get install -y git-flow
        fi
    elif command -v apk >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            apk add --no-cache gitflow-avh
        elif command -v sudo >/dev/null 2>&1; then
            sudo apk add --no-cache gitflow-avh
        else
            apk add --no-cache gitflow-avh
        fi
    elif command -v dnf >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            dnf install -y gitflow
        elif command -v sudo >/dev/null 2>&1; then
            sudo dnf install -y gitflow
        else
            dnf install -y gitflow
        fi
    elif command -v yum >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            yum install -y gitflow
        elif command -v sudo >/dev/null 2>&1; then
            sudo yum install -y gitflow
        else
            yum install -y gitflow
        fi
    elif command -v brew >/dev/null 2>&1; then
        brew install git-flow-avh
    elif command -v pacman >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            pacman -S --noconfirm gitflow-avh
        elif command -v sudo >/dev/null 2>&1; then
            sudo pacman -S --noconfirm gitflow-avh
        else
            pacman -S --noconfirm gitflow-avh
        fi
    elif command -v zypper >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            zypper --non-interactive install git-flow
        elif command -v sudo >/dev/null 2>&1; then
            sudo zypper --non-interactive install git-flow
        else
            zypper --non-interactive install git-flow
        fi
    else
        zz_log e "Unable to install git-flow automatically on this system."
        zz_log - "Please install it manually and run release again."
        exit 1
    fi

    if ! git flow version >/dev/null 2>&1; then
        zz_log e "git-flow is still unavailable after installation attempt."
        exit 1
    fi
    zz_log s "git-flow installed successfully."
fi 

# This script is a utility to dispatch calls to various utilities with the same prefix.
zz_dispatch $0 "$@"
