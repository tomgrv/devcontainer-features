#!/bin/sh
set -e

zz_log i "Configuring GitHub Copilot Agent Environment..."

# Get configuration from environment variables
LANGUAGE_SERVERS="${LANGUAGESERVERS:-typescript python rust go}"
DEVELOPMENT_TOOLS="${DEVELOPMENTTOOLS:-curl git jq tree ripgrep fd}"
PACKAGE_MANAGERS="${PACKAGEMANAGERS:-npm pip cargo}"
ENABLE_LANGUAGE_SUPPORT="${ENABLELANGUAGESUPPORT:-true}"

# Install development tools
zz_log i "Starting development tools installation..."
$(dirname $0)/install-copilot-dev-tools.sh

# Install package managers
zz_log i "Starting package managers installation..."
$(dirname $0)/install-copilot-package-managers.sh

# Install language servers if language support is enabled
if [ "$ENABLE_LANGUAGE_SUPPORT" = "true" ]; then
    zz_log i "Starting language servers installation..."
    $(dirname $0)/install-copilot-language-servers.sh
else
    zz_log i "Language support disabled, skipping language servers"
fi

# Set up environment variables for better Copilot agent performance
zz_log i "Setting up environment variables..."

# Add common paths to PATH if they don't exist
PATHS_TO_ADD="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin"
for path in $(echo $PATHS_TO_ADD | tr ':' ' '); do
    if [ -d "$path" ] && [[ ":$PATH:" != *":$path:"* ]]; then
        echo "export PATH=\"$path:\$PATH\"" >> ~/.bashrc
        zz_log i "Added $path to PATH"
    fi
done

# Create useful aliases for Copilot agent development
zz_log i "Setting up development aliases..."
cat >> ~/.bashrc << 'EOF'

# GitHub Copilot Agent Environment aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'
alias tree='tree -C'

# Development shortcuts
alias gitlog='git log --oneline --graph --decorate --all'
alias gitst='git status -s'
alias py='python3'
alias serve='python3 -m http.server'

# Copilot-friendly shortcuts
alias ports='netstat -tuln'
alias processes='ps aux'
alias diskusage='df -h'

EOF

zz_log s "GitHub Copilot Agent Environment configuration completed!"
zz_log i "Available tools: {B $DEVELOPMENT_TOOLS}"
zz_log i "Package managers: {B $PACKAGE_MANAGERS}"
if [ "$ENABLE_LANGUAGE_SUPPORT" = "true" ]; then
    zz_log i "Language servers: {B $LANGUAGE_SERVERS}"
fi