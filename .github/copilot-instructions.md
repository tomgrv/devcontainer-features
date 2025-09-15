<!-- @format -->

# Devcontainer Features Repository

This repository contains a collection of devcontainer features that enhance development environments. It provides Git utilities, hooks, version management, and other development tools that can be installed individually or as a complete development setup.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup

- Clone the repository and navigate to the root directory
- Node.js and npm are required (tested with Node v20.19.5, npm 10.8.2)
- Run `npm install` to install dependencies -- takes 3 seconds. NEVER CANCEL. Set timeout to 5+ minutes.
- Install missing prettier plugin: `npm install prettier-plugin-sh` -- takes 1 second. Required for linting.
- Fix common-utils symlinks with: `find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \; && find src/common-utils/ -type f -name "_*.sh" | while read file; do ln -sf $file src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//'); done`
- Create workaround for install script typo: `ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh`

### Building and Testing

- `npm run lint` -- lints staged files using lint-staged. Takes 1-2 seconds. Set timeout to 2+ minutes.
- `npm test` -- currently only outputs a warning message, no actual tests exist  
- `npm run release` -- creates release using commit-and-tag-version
- Install devcontainers CLI: `npm install -g @devcontainers/cli` -- takes 30-60 seconds. Set timeout to 3+ minutes.

### Installing Features

- Local installation script: `./install.sh -h` for help
- Install stubs only: `./install.sh -s` -- takes 10-15 seconds in git repo
- Install specific feature: `./install.sh gitutils` -- takes 5-10 seconds
- Install all default features: `./install.sh -a` -- takes 15-20 seconds
- Via npx: `npx tomgrv/devcontainer-features -h` -- downloads and runs, takes 2 seconds after first time

### Validation

- Features validate automatically during GitHub Actions CI
- No manual tests exist for individual features
- Install validation: Create test directory, run `git init`, then run install commands
- Check created files in `.devcontainer/` and `.vscode/` directories after installation

## Repository Structure

### Key Features (src/ directory)

- **gitutils**: Git aliases and utilities for workflow automation
- **githooks**: Development environment setup with commitlint, prettier, lint-staged
- **gitversion**: GitVersion tool for semantic versioning based on Git history
- **act**: Nektos/act tool for running GitHub Actions locally
- **pecl**: PHP Extension Community Library (PECL) installer
- **larasets**: Laravel-specific development tools
- **common-utils**: Shared utilities used by other features

### Configuration Files

- `package.json`: Main package configuration with npm scripts and dependencies
- `install.sh`: Main installation script (has typo bug - see workaround above)
- `.github/workflows/`: CI/CD pipelines for validation and publishing
- `stubs/`: Template files for devcontainer and VS Code configuration

## Known Issues and Workarounds

### Critical Installation Bug

The `install.sh` script has a typo on line 9: references `_zz_logs.sh` but file is `_zz_log.sh`.
**WORKAROUND**: Always run this after cloning: `ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh`

### Container vs Local Installation

- Features are designed for devcontainer environments
- Local installation has limited functionality ("No writeable directory found" messages are normal)
- Some features require Docker or specific dependencies not available in local environment

## Validation Scenarios

### Basic Feature Installation Test

1. Create test directory: `mkdir /tmp/feature-test && cd /tmp/feature-test`
2. Initialize git: `git init`
3. Install stubs: `/path/to/install.sh -s`
4. Verify created files: `ls -la .devcontainer/ .vscode/`
5. Check devcontainer.json contains expected features

### NPX Installation Test

1. Create clean directory: `mkdir /tmp/npx-test && cd /tmp/npx-test`
2. Run: `npx tomgrv/devcontainer-features -s`
3. Verify same stubs are created as local installation

### Linting Test

1. Stage some files: `git add .`
2. Run: `npm run lint`
3. Should process staged files or show "No staged files found"

## Common Commands Reference

### Repository Setup (first time)

```bash
git clone <repo-url>
cd devcontainer-features
npm install
npm install prettier-plugin-sh
find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;
find src/common-utils/ -type f -name "_*.sh" | while read file; do ln -sf $file src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//'); done
ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh
```

### Quick Feature Test

```bash
cd /tmp && mkdir test-features && cd test-features
git init
/path/to/devcontainer-features/install.sh -s
ls -la .devcontainer/ .vscode/
```

### Pre-commit Validation

```bash
git add .
npm run lint
# Make any needed changes, then commit
```

## Directory Structure Reference

```
.
├── .devcontainer/          # Repository's own devcontainer config
├── .github/workflows/      # CI/CD: validate.yml, release.yaml
├── .vscode/               # VS Code configuration
├── src/                   # All devcontainer features
│   ├── common-utils/      # Shared utilities and scripts
│   ├── gitutils/          # Git aliases and utilities
│   ├── githooks/          # Git hooks and linting setup
│   ├── gitversion/        # GitVersion semantic versioning
│   ├── act/               # GitHub Actions local runner
│   ├── pecl/              # PHP extensions
│   └── larasets/          # Laravel development tools
├── stubs/                 # Template files for new projects
├── install.sh            # Main installation script (has typo bug)
├── package.json          # npm configuration and scripts
└── README.md             # Basic usage documentation
```

## Expected Timing

- `npm install`: 3 seconds
- `npm install prettier-plugin-sh`: 1 second
- `npm run lint`: 1-2 seconds (without staged files), up to 15 seconds (with files)
- `./install.sh -s`: 10-15 seconds
- `./install.sh -a`: 15-20 seconds  
- `npx tomgrv/devcontainer-features`: 2 seconds (after first download)
- Feature installation: 5-10 seconds per feature

**NEVER CANCEL** any npm or installation commands. Always set timeouts of 5+ minutes for safety.
