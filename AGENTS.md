<!-- @format -->

# AGENTS.md - Devcontainer Features Repository Guide

This guide helps GitHub Copilot and other AI agents understand how to work effectively with the `tomgrv/devcontainer-features` repository. It provides comprehensive context about the repository structure, development patterns, and owner preferences.

## Repository Overview

**tomgrv/devcontainer-features** is a collection of VS Code Dev Container features that enhance development environments with Git utilities, hooks, version management, and specialized tools. The repository follows a modular architecture where each feature can be used independently or as part of a complete development setup.

### Core Philosophy

- **Minimal, surgical changes**: Make the smallest possible modifications
- **Modular design**: Each feature is self-contained but can depend on others
- **Development automation**: Focus on Git workflows, commit standards, and developer productivity
- **Container-first**: Designed primarily for devcontainer environments

## Repository Architecture

### Features (`src/` directory)

The repository contains 7 main devcontainer features:

#### 1. **common-utils** (Foundation)

- **Purpose**: Shared utilities and base functionality for all other features
- **Key Components**: `jq`, `dos2unix`, color logging (`zz_colors`), argument parsing (`zz_args`), JSON validation/normalization
- **Dependencies**: `ghcr.io/devcontainers/features/common-utils`
- **Version**: 3.17.0
- **Usage**: Required by most other features as a dependency

#### 2. **gitutils** (Git Workflow Automation)

- **Purpose**: Comprehensive Git aliases and workflow utilities
- **Key Components**: 40+ Git aliases, GitFlow integration, interactive utilities
- **Dependencies**: `common-utils`, `gitversion`, `node`
- **Version**: 5.25.0
- **Notable Features**:
    - Git aliases: `git co`, `git go`, `git amend`, `git sync`, `git align`
    - Interactive tools: `git fixup`, `git integrate`, `git degit`
    - Release management: `git release-beta`, `git release-prod`

#### 3. **githooks** (Development Environment Standards)

- **Purpose**: Automated code quality and commit standards
- **Key Components**: commitlint, prettier, lint-staged, husky, conventional commits
- **Dependencies**: `common-utils`, `gitutils`, `node`
- **Version**: 5.11.3
- **Enforces**: Conventional commits, code formatting, pre-commit checks

#### 4. **gitversion** (Semantic Versioning)

- **Purpose**: Automated version calculation based on Git history
- **Key Components**: GitVersion tool for .NET-based versioning
- **Dependencies**: `common-utils`, `dotnet`
- **Version**: 5.2.1
- **Usage**: Calculates semantic versions from Git tags and branch patterns

#### 5. **act** (Local GitHub Actions)

- **Purpose**: Run GitHub Actions workflows locally
- **Key Components**: nektos/act tool
- **Dependencies**: `docker-in-docker`
- **Version**: 1.6.1
- **Usage**: Test GitHub Actions workflows without pushing to GitHub

#### 6. **pecl** (PHP Extensions)

- **Purpose**: Install PHP extensions via PECL
- **Key Components**: PECL package manager
- **Dependencies**: `php` (v8.2)
- **Version**: 1.0.7
- **Default**: Installs `zip` extension

#### 7. **larasets** (Laravel Development Environment)

- **Purpose**: Laravel-specific development tools and configurations
- **Key Components**: Laravel Sail, Composer, Doppler integration
- **Dependencies**: `docker-in-docker`, `node`, `php` (v8.3), `common-utils`, `doppler`
- **Version**: 5.10.2
- **Features**: Xdebug configuration, SQLite setup, development environment variables

### Key Configuration Files

- **`package.json`**: Main project configuration with npm scripts, prettier settings, commitlint rules
- **`install.sh`**: Universal installation script (⚠️ has known typo bug)
- **`.github/workflows/`**: CI/CD automation (`validate.yml`, `release.yaml`)
- **`stubs/`**: Template files for `.devcontainer/` and `.vscode/` configurations
- **`.github/copilot-instructions.md`**: Existing technical setup guide (complementary to this file)

## Development Patterns & Owner Preferences

### Code Style & Standards

```json
{
    "prettier": {
        "semi": false,
        "singleQuote": true,
        "tabWidth": 4,
        "trailingComma": "es5"
    }
}
```

### Commit Standards

- **Format**: Conventional Commits (`feat:`, `fix:`, `chore:`)
- **Scopes**: `gitutils`, `githooks`, `gitversion`, `larasets`, `pecl`, `common-utils`
- **Tools**: commitlint, devmoji, git-precommit-checks
- **Example**: `feat(gitutils): add new git align command`

### Feature Development Pattern

```bash
# 1. Create new feature directory
mkdir src/my-feature

# 2. Required files
touch src/my-feature/devcontainer-feature.json # Feature definition
touch src/my-feature/install.sh                # Installation script
touch src/my-feature/README.md                 # Documentation

# 3. Optional structure
mkdir src/my-feature/stubs # Template files
```

### Version Management

- **Tool**: commit-and-tag-version (semantic release)
- **Pattern**: Major.Minor.Patch (1.0.0)
- **Automation**: GitVersion calculates versions from Git history
- **Files**: Updates `package.json`, `composer.json`, `VERSION`

## Common Development Workflows

### 🚀 Feature Development

1. **Setup Environment** (use existing `.github/copilot-instructions.md` setup commands)
2. **Create Feature Branch**: `git checkout -b feature/new-feature`
3. **Develop Feature**: Focus on single feature in `src/feature-name/`
4. **Test Locally**: `./install.sh feature-name`
5. **Validate**: `npm run lint` (staged files only)
6. **Commit**: Use conventional commit format

### 🐛 Bug Fixes

1. **Identify Scope**: Which feature(s) are affected
2. **Minimal Changes**: Only modify necessary files
3. **Test Fix**: Use temporary test environment
4. **Validate**: Ensure existing functionality not broken

### 📝 Documentation Updates

1. **Feature README**: Update `src/feature/README.md`
2. **Main README**: Update root `README.md` if adding new features
3. **No Build Required**: Documentation changes don't need linting/building

### 🔧 Configuration Changes

1. **Feature Config**: `src/feature/devcontainer-feature.json`
2. **Dependencies**: Update `dependsOn` and `installsAfter`
3. **VSCode Settings**: Add to `customizations.vscode`
4. **Validation**: Use devcontainer action to validate JSON

## Installation & Usage Patterns

### NPX Installation (Recommended)

```bash
# Install stubs only
npx tomgrv/devcontainer-features -s

# Install specific feature
npx tomgrv/devcontainer-features -- gitutils

# Install full development setup
npx tomgrv/devcontainer-features -a
```

### Direct Installation

```bash
# Clone and use install script
git clone https://github.com/tomgrv/devcontainer-features.git
./install.sh -s                # stubs only
./install.sh gitutils githooks # specific features
./install.sh -a                # all features
```

### Container Usage

```json
{
    "features": {
        "ghcr.io/tomgrv/devcontainer-features/gitutils:1": {},
        "ghcr.io/tomgrv/devcontainer-features/githooks:1": {}
    }
}
```

## Troubleshooting Guide

### Common Issues

- **"No staged files found"** → Normal when running `npm run lint` with no changes
- **"prettier-plugin-sh not found"** → Run: `npm install prettier-plugin-sh`
- **Install script typo** → Known issue in line 9, use workaround from copilot-instructions.md
- **Symlink issues** → Run chmod and symlink commands from setup guide

## Agent Guidelines

### When Working on This Repository
1. **Read copilot-instructions.md first**: Contains critical setup commands and known issues
2. **Focus on specific features**: Don't make repository-wide changes unless requested
3. **Respect modular architecture**: Each feature should be self-contained
4. **Test changes**: Use temporary environments, don't commit test artifacts
5. **Follow existing patterns**: Match coding style, commit format, and file organization

### Workflow Automation Preferences
The repository owner (tomgrv) heavily values automation and developer productivity:

#### Git Workflow Automation
- **Aliases for Speed**: Provides 40+ Git aliases for common operations
- **Interactive Tools**: Prefers tools that guide users through complex operations
- **Conventional Commits**: Strictly enforces commit message standards
- **Automated Versioning**: Uses GitVersion for semantic release automation

#### Code Quality Automation  
- **Pre-commit Hooks**: Automatically formats and validates code before commits
- **Lint-staged**: Only processes changed files for efficiency
- **JSON Normalization**: Automatically formats and validates JSON configurations
- **Prettier Integration**: Consistent code formatting across all file types

#### Development Environment Automation
- **One-command Setup**: `install.sh -a` sets up complete development environment
- **Template Generation**: Stub files automatically configure containers and VS Code
- **Dependency Management**: Features automatically install required dependencies
- **Container Integration**: Seamless integration with VS Code Dev Containers

### Performance Expectations

- **npm install**: ~3 seconds
- **./install.sh -s**: 10-15 seconds
- **./install.sh -a**: 15-20 seconds
- **npm run lint**: 1-15 seconds (depending on staged files)
- **Automation over Manual**: If doing something twice, create a script/alias
- **Developer Experience**: Optimize for developer productivity and ease of use

### Environment Notes

- **Container vs Local**: Features designed for devcontainer environments
- **"No writeable directory"**: Normal message for local installation
- **Docker Dependencies**: Some features require Docker/container environment

- Don't create manual processes where automation is possible
- Don't ignore existing linting and formatting rules
## Agent Guidelines

### When Working on This Repository

1. **Read copilot-instructions.md first**: Contains critical setup commands and known issues
2. **Focus on specific features**: Don't make repository-wide changes unless requested
3. **Respect modular architecture**: Each feature should be self-contained
4. **Test changes**: Use temporary environments, don't commit test artifacts
5. **Follow existing patterns**: Match coding style, commit format, and file organization

### Best Practices

- **Minimal changes**: Only modify files directly related to the task
- **Use existing tooling**: Leverage npm scripts, prettier, commitlint
- **Respect dependencies**: Understand feature dependency chain
- **Document changes**: Update README files when adding features
- **Test thoroughly**: Use install.sh to validate changes work
## Quick Reference Commands

### Essential Bootstrap (Development/Testing Only)
```bash
# Core setup - DO NOT COMMIT these changes
cd /home/runner/work/devcontainer-features/devcontainer-features
npm install && npm install prettier-plugin-sh
find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;
find src/common-utils/ -type f -name "_*.sh" | while read file; do 
  ln -sf $file src/common-utils/$(basename $file | sed 's/^_//;s/.sh$//'); 
done
ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh
```

### Testing & Validation
```bash
# Quick feature test
mkdir /tmp/test-features && cd /tmp/test-features && git init
/home/runner/work/devcontainer-features/devcontainer-features/install.sh -s
ls -la .devcontainer/ .vscode/

# Lint staged changes
git add . && npm run lint

# Test specific feature
./install.sh gitutils
```

### NPX Commands
```bash
npx tomgrv/devcontainer-features -h      # Help
npx tomgrv/devcontainer-features -s      # Stubs only  
npx tomgrv/devcontainer-features -a      # All features
npx tomgrv/devcontainer-features -- gitutils githooks  # Specific features
```

## File Structure Reference

```
devcontainer-features/
├── .github/
│   ├── copilot-instructions.md         # Technical setup guide
│   └── workflows/
│       ├── validate.yml                # PR validation
│       └── release.yaml                # Auto-publish features
├── src/                                # Feature definitions
│   ├── common-utils/                   # Foundation utilities
│   ├── gitutils/                       # Git workflow tools
│   ├── githooks/                       # Code quality hooks
│   ├── gitversion/                     # Semantic versioning
│   ├── act/                           # GitHub Actions locally
│   ├── pecl/                          # PHP extensions
│   └── larasets/                      # Laravel development
├── stubs/                             # Template configurations
│   ├── .devcontainer/                 # Container templates
│   └── .vscode/                       # VS Code templates
├── install.sh                         # Universal installer
├── package.json                       # Project configuration
└── AGENTS.md                          # This file
```

## Owner Communication Style

### Commit Message Preferences
- **Format**: `type(scope): description`
- **Types**: feat, fix, chore, docs, style, refactor, perf, test
- **Scopes**: Feature names (gitutils, githooks, etc.)
- **Style**: Imperative mood, lowercase, no period

### Code Review Expectations  
- **Focus**: Minimal changes, surgical fixes
- **Testing**: Evidence that changes work (screenshots for UI, test output for features)
- **Documentation**: Update READMEs for new features or significant changes
- **Backwards Compatibility**: Don't break existing feature dependencies

### Communication Patterns
- **Technical**: Prefers specific, actionable feedback
- **Automation**: Values tools over manual processes
- **Modularity**: Appreciates clean separation of concerns
- **Developer Experience**: Focuses on improving development workflows

## Technical Context

### Known Limitations
- **Container Focus**: Some features only work in devcontainer environments
- **Docker Dependencies**: act and larasets require Docker-in-Docker
- **PHP Version Constraints**: pecl requires PHP 8.2+, larasets uses PHP 8.3
- **Node Dependencies**: Several features require Node.js LTS

### Performance Considerations
- **Feature Loading**: common-utils should load first (dependency order)
- **Installation Time**: Full setup takes 15-20 seconds
- **Resource Usage**: Docker-based features consume more resources
- **Network Dependency**: Features download from GitHub Container Registry

### Security Notes
- **Symlinks**: Temporary symlinks for development should not be committed
- **Permissions**: Shell scripts need execute permissions
- **Environment Variables**: larasets includes development-specific env vars
- **Docker Access**: Some features require elevated Docker permissions


### What NOT to Do

- Don't commit symlinks or build artifacts unless specifically part of the feature
- Don't modify package.json unless required for the specific feature
- Don't change repository structure without explicit request
- Don't break existing feature dependencies
- Don't commit temporary test files or environments

## Integration Points

### GitHub Actions

- **validate.yml**: Validates devcontainer-feature.json files on PRs
- **release.yaml**: Publishes features to GitHub Container Registry on main branch

### VSCode Integration

- **Extensions**: Each feature can specify VSCode extensions
- **Settings**: Features can customize editor behavior
- **Tasks**: Custom tasks for development workflows

### Container Registry

- **Published Location**: `ghcr.io/tomgrv/devcontainer-features/[feature-name]`
- **Versioning**: Semantic versioning with Git tags
- **Dependencies**: Features can depend on other published features

This guide should help agents understand the repository structure, respect the owner's development patterns, and make effective contributions while maintaining the modular, automation-focused philosophy of the project.
