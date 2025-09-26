#!/bin/sh
set -e

echo "Installing development tools for GitHub Copilot Agent Environment..."

# Define a simple logging function if zz_log is not available
if ! command -v zz_log >/dev/null 2>&1; then
    zz_log() {
        case $1 in
            "i") echo "→ $2" ;;
            "s") echo "✔ $2" ;;
            "w") echo "⚠ $2" ;;
            "e") echo "✖ $2" ;;
            *) echo "$*" ;;
        esac
    }
fi

# Get the development tools list from options
DEVELOPMENT_TOOLS="${DEVELOPMENTTOOLS:-curl git jq tree ripgrep fd}"

zz_log i "Installing development tools: $DEVELOPMENT_TOOLS"

# Update package lists
if command -v apt-get >/dev/null 2>&1; then
    apt-get update
elif command -v apk >/dev/null 2>&1; then
    apk update
fi

for tool in $DEVELOPMENT_TOOLS; do
    case $tool in
        "curl")
            zz_log i "Installing curl..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install -y curl
            elif command -v apk >/dev/null 2>&1; then
                apk add curl
            elif command -v yum >/dev/null 2>&1; then
                yum install -y curl
            fi
            zz_log s "curl installed"
            ;;
        "git")
            zz_log i "Installing git..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install -y git
            elif command -v apk >/dev/null 2>&1; then
                apk add git
            elif command -v yum >/dev/null 2>&1; then
                yum install -y git
            fi
            zz_log s "git installed"
            ;;
        "jq")
            zz_log i "Installing jq..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install -y jq
            elif command -v apk >/dev/null 2>&1; then
                apk add jq
            elif command -v yum >/dev/null 2>&1; then
                yum install -y jq
            fi
            zz_log s "jq installed"
            ;;
        "tree")
            zz_log i "Installing tree..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install -y tree
            elif command -v apk >/dev/null 2>&1; then
                apk add tree
            elif command -v yum >/dev/null 2>&1; then
                yum install -y tree
            fi
            zz_log s "tree installed"
            ;;
        "ripgrep"|"rg")
            zz_log i "Installing ripgrep..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install -y ripgrep
            elif command -v apk >/dev/null 2>&1; then
                apk add ripgrep
            elif command -v yum >/dev/null 2>&1; then
                yum install -y ripgrep
            fi
            zz_log s "ripgrep installed"
            ;;
        "fd"|"fd-find")
            zz_log i "Installing fd..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install -y fd-find
            elif command -v apk >/dev/null 2>&1; then
                apk add fd
            elif command -v yum >/dev/null 2>&1; then
                yum install -y fd-find
            fi
            zz_log s "fd installed"
            ;;
        *)
            zz_log w "Unknown development tool: $tool"
            ;;
    esac
done

zz_log s "Development tools installation completed"