#!/bin/sh

# Ensure this runs inside a git repository; nothing to do otherwise.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

# Ensure git-flow is available before initializing.
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
        zz_log - "Please install it manually and run again."
        exit 1
    fi

    if ! git flow version >/dev/null 2>&1; then
        zz_log e "git-flow is still unavailable after installation attempt."
        exit 1
    fi
    zz_log s "git-flow installed successfully."
fi

master_branch="${GITFLOW_MASTER_BRANCH:-main}"
develop_branch="${GITFLOW_DEVELOP_BRANCH:-develop}"
feature_prefix="${GITFLOW_FEATURE_PREFIX:-feature/}"
bugfix_prefix="${GITFLOW_BUGFIX_PREFIX:-bugfix/}"
release_prefix="${GITFLOW_RELEASE_PREFIX:-release/}"
hotfix_prefix="${GITFLOW_HOTFIX_PREFIX:-hotfix/}"
support_prefix="${GITFLOW_SUPPORT_PREFIX:-support/}"
versiontag_prefix="${GITFLOW_VERSIONTAG_PREFIX:-v}"

# 'git flow init -f' recomputes the master/develop suggestion from gitflow.branch.*
# (falling back to an existing same-named branch, or these values on a fresh repo).
git config gitflow.branch.master "$master_branch"
git config gitflow.branch.develop "$develop_branch"

# Prefixes are only read from --system/--global config by 'init', so pass them
# explicitly to avoid the (empty) built-in defaults, in particular for the tag prefix.
git flow init -d -f \
    -p "$feature_prefix" -b "$bugfix_prefix" -r "$release_prefix" \
    -x "$hotfix_prefix" -s "$support_prefix" -t "$versiontag_prefix" \
    >/dev/null 2>&1 && zz_log s "git-flow initialized successfully." || zz_log e "Failed to initialize git-flow."
