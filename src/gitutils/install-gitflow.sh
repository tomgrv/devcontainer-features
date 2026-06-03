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

# Initialize git-flow in the repository if not already initialized. Use config values if available, otherwise use defaults.
_feature_branch=$(jq -r '.gitflow.featureBranch' $source/config.json 2>/dev/null || echo "feature")
_release_branch=$(jq -r '.gitflow.releaseBranch' $source/config.json 2>/dev/null || echo "release")
_hotfix_branch=$(jq -r '.gitflow.hotfixBranch' $source/config.json 2>/dev/null || echo "hotfix")
_support_branch=$(jq -r '.gitflow.supportBranch' $source/config.json 2>/dev/null || echo "support")
_develop_branch=$(jq -r '.gitflow.developBranch' $source/config.json 2>/dev/null || echo "develop")
_master_branch=$(jq -r '.gitflow.masterBranch' $source/config.json 2>/dev/null || echo "master")

# Configure git-flow with the specified branch names. Use -d to skip prompts and -f to force reinitialization if already initialized.
git flow init -d -f $_feature_branch -r $_release_branch -h $_hotfix_branch -s $_support_branch -d $_develop_branch -m $_master_branch >/dev/null 2>&1 && zz_log s "git-flow initialized successfully." || zz_log e "Failed to initialize git-flow."

git config --global gitflow.branch.feature
