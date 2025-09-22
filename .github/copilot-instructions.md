<!-- @format -->

# Devcontainer Features Repository

This repository contains a collection of devcontainer features that enhance development environments. It provides Git utilities, hooks, version management, and other development tools that can be installed individually or as a complete development setup.

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Quick Reference for Copilot Agents

**CRITICAL**: This repository has specific setup requirements and known issues. Follow the bootstrap commands exactly to avoid common problems.

**NEVER CANCEL** any npm or installation commands - they complete quickly but require proper timeouts.

## Essential Setup Commands (Run These First)

```bash
# 1. Bootstrap the repository (4 seconds total)
npm install                                    # 3 seconds - installs dependencies
npm install prettier-plugin-sh               # 1 second - required for linting

# 2. Fix known symlink issues (5 seconds)
find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;
find src/common-utils/ -type f -name "_*.sh" | while read file; do 
  ln -sf $file src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//'); 
done

# 3. Workaround for install script typo (1 second)
ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh
```

**Set timeouts to 5+ minutes for ALL commands to prevent premature cancellation.**

## Core Development Commands

| Command | Purpose | Duration | Notes |
|---------|---------|----------|-------|
| `npm run lint` | Lint staged files | 1-2s (empty), 15s (with files) | Uses lint-staged, only lints staged files |
| `npm test` | Run tests | <1s | Currently only shows warning - no tests exist |
| `./install.sh -s` | Install stubs only | 10-15s | Creates `.devcontainer/` and `.vscode/` configs |
| `./install.sh -a` | Install all features | 15-20s | Full feature installation |
| `./install.sh gitutils` | Install specific feature | 5-10s | Install individual feature by name |
| `npx tomgrv/devcontainer-features -h` | NPX installation | 2s (cached) | Alternative installation method |

**Validation Commands:**
```bash
# Quick feature test
mkdir /tmp/test-features && cd /tmp/test-features
git init
/path/to/devcontainer-features/install.sh -s
ls -la .devcontainer/ .vscode/  # Verify files created
```

## Repository Architecture

### 7 Devcontainer Features (`src/` directory)

| Feature | Purpose | Key Files |
|---------|---------|-----------|
| **gitutils** | Git aliases and workflow automation | Aliases for common git operations |
| **githooks** | Development environment setup | commitlint, prettier, lint-staged, husky |
| **gitversion** | Semantic versioning | GitVersion tool for automated versioning |
| **act** | Local GitHub Actions | Nektos/act for running actions locally |
| **pecl** | PHP Extensions | PECL installer for PHP development |
| **larasets** | Laravel tools | Laravel-specific development utilities |
| **common-utils** | Shared utilities | Scripts used by other features |

### Key Configuration Files

- `package.json` - Main configuration with npm scripts, dependencies, prettier, commitlint
- `install.sh` - Installation script (**has typo bug** - see workaround above)
- `.github/workflows/` - CI/CD: `validate.yml`, `release.yaml`
- `stubs/` - Template files for `.devcontainer/` and `.vscode/` configs

## Critical Issues & Workarounds

### 🐛 Install Script Typo (Line 9)
**Problem**: Script references `_zz_logs.sh` but file is `_zz_log.sh`  
**Fix**: `ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh`

### 📦 Missing Prettier Plugin  
**Problem**: Linting fails without `prettier-plugin-sh`  
**Fix**: `npm install prettier-plugin-sh` (included in setup commands above)

### 🔗 Broken Symlinks in common-utils
**Problem**: Shell scripts not executable and symlinks missing  
**Fix**: Run the chmod and symlink commands from setup section above

### 🐳 Container vs Local Behavior
- Features designed for **devcontainer environments**
- Local installation shows "No writeable directory found" - **this is normal**
- Some features require Docker/specific dependencies not available locally

## Common Workflows for Copilot Agents

### 🚀 First-time Repository Setup
```bash
# Run this exactly - all commands are required
cd /home/runner/work/devcontainer-features/devcontainer-features
npm install
npm install prettier-plugin-sh
find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;
find src/common-utils/ -type f -name "_*.sh" | while read file; do 
  ln -sf $file src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//'); 
done
ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh
```

### 🧪 Testing Changes
```bash
# 1. Create test environment
mkdir /tmp/feature-test && cd /tmp/feature-test
git init

# 2. Test installation
/home/runner/work/devcontainer-features/devcontainer-features/install.sh -s

# 3. Verify results
ls -la .devcontainer/ .vscode/
cat .devcontainer/devcontainer.json  # Should contain features array
```

### ✅ Pre-commit Validation
```bash
git add .                # Stage your changes
npm run lint            # Lint staged files (1-15 seconds)
# Fix any linting issues, then commit
```

### 📦 NPX Alternative Testing
```bash
# Test the NPX installation method
mkdir /tmp/npx-test && cd /tmp/npx-test
git init
npx tomgrv/devcontainer-features -s
# Should create same files as local installation
```

## Performance Expectations

⚡ **Timing Reference** (all validated):

| Operation | Expected Duration | Timeout Setting |
|-----------|------------------|-----------------|
| `npm install` | 3 seconds | 5+ minutes |
| `npm install prettier-plugin-sh` | 1 second | 2+ minutes |
| `npm run lint` (no files) | 1-2 seconds | 2+ minutes |
| `npm run lint` (with files) | up to 15 seconds | 2+ minutes |
| `./install.sh -s` | 10-15 seconds | 2+ minutes |
| `./install.sh -a` | 15-20 seconds | 3+ minutes |
| `./install.sh <feature>` | 5-10 seconds | 2+ minutes |
| `npx tomgrv/devcontainer-features` | 2 seconds (cached) | 2+ minutes |

⚠️ **CRITICAL**: Always set generous timeouts. Commands complete quickly but need buffer for system variations.

## Troubleshooting Guide

**❌ "No staged files found"** → Normal when running `npm run lint` with no staged changes  
**❌ "No writeable directory found"** → Normal for local installation, features designed for containers  
**❌ "_zz_logs.sh: No such file"** → Run the typo workaround: `ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh`  
**❌ "prettier-plugin-sh not found"** → Run: `npm install prettier-plugin-sh`  
**❌ "Permission denied" on scripts** → Run: `find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;`
