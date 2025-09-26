#!/bin/sh
set -e

echo "Installing package managers for GitHub Copilot Agent Environment..."

# Get the package managers list from options
PACKAGE_MANAGERS="${PACKAGEMANAGERS:-npm pip cargo}"

zz_log i "Installing package managers: {B $PACKAGE_MANAGERS}"

for manager in $PACKAGE_MANAGERS; do
    case $manager in
        "npm")
            zz_log i "Ensuring npm is available..."
            if ! command -v npm >/dev/null 2>&1; then
                if command -v apt-get >/dev/null 2>&1; then
                    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
                    apt-get install -y nodejs
                elif command -v apk >/dev/null 2>&1; then
                    apk add nodejs npm
                elif command -v yum >/dev/null 2>&1; then
                    curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
                    yum install -y nodejs npm
                fi
                zz_log s "npm installed"
            else
                zz_log s "npm already available"
            fi
            ;;
        "pip"|"pip3")
            zz_log i "Ensuring pip is available..."
            if ! command -v pip >/dev/null 2>&1 && ! command -v pip3 >/dev/null 2>&1; then
                if command -v apt-get >/dev/null 2>&1; then
                    apt-get install -y python3-pip
                elif command -v apk >/dev/null 2>&1; then
                    apk add python3 py3-pip
                elif command -v yum >/dev/null 2>&1; then
                    yum install -y python3-pip
                fi
                zz_log s "pip installed"
            else
                zz_log s "pip already available"
            fi
            ;;
        "cargo")
            zz_log i "Ensuring cargo is available..."
            if ! command -v cargo >/dev/null 2>&1; then
                # Install Rust and Cargo via rustup
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                . ~/.cargo/env
                zz_log s "cargo installed"
            else
                zz_log s "cargo already available"
            fi
            ;;
        "composer")
            zz_log i "Ensuring composer is available..."
            if ! command -v composer >/dev/null 2>&1; then
                # Install Composer for PHP
                curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                zz_log s "composer installed"
            else
                zz_log s "composer already available"
            fi
            ;;
        *)
            zz_log w "Unknown package manager: {B $manager}"
            ;;
    esac
done

zz_log s "Package managers installation completed"