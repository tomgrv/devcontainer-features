#!/bin/sh
set -e

echo "Installing language servers for GitHub Copilot Agent Environment..."

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

# Get the language servers list from options
LANGUAGE_SERVERS="${LANGUAGESERVERS:-typescript python rust go}"

zz_log i "Installing language servers: $LANGUAGE_SERVERS"

for server in $LANGUAGE_SERVERS; do
    case $server in
        "typescript"|"ts")
            zz_log i "Installing TypeScript language server..."
            if command -v npm >/dev/null 2>&1; then
                npm install -g typescript typescript-language-server
                zz_log s "TypeScript language server installed"
            else
                zz_log w "npm not found, skipping TypeScript language server"
            fi
            ;;
        "python"|"py")
            zz_log i "Installing Python language server..."
            if command -v pip >/dev/null 2>&1; then
                pip install python-lsp-server[all] pylsp-mypy
                zz_log s "Python language server installed"
            elif command -v pip3 >/dev/null 2>&1; then
                pip3 install python-lsp-server[all] pylsp-mypy
                zz_log s "Python language server installed"
            else
                zz_log w "pip not found, skipping Python language server"
            fi
            ;;
        "rust"|"rs")
            zz_log i "Installing Rust analyzer..."
            if command -v cargo >/dev/null 2>&1; then
                # rust-analyzer is typically installed via rustup
                if command -v rustup >/dev/null 2>&1; then
                    rustup component add rust-analyzer
                    zz_log s "Rust analyzer installed"
                else
                    zz_log w "rustup not found, skipping rust-analyzer"
                fi
            else
                zz_log w "cargo not found, skipping Rust analyzer"
            fi
            ;;
        "go"|"golang")
            zz_log i "Installing Go language server..."
            if command -v go >/dev/null 2>&1; then
                go install golang.org/x/tools/gopls@latest
                zz_log s "Go language server installed"
            else
                zz_log w "go not found, skipping Go language server"
            fi
            ;;
        *)
            zz_log w "Unknown language server: $server"
            ;;
    esac
done

zz_log s "Language server installation completed"