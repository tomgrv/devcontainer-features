---
applyTo: '**'
---

<!-- @format -->

# Devcontainer Features Repository

This repository contains 7 devcontainer features installed via `install.sh` or `npx tomgrv/devcontainer-features`.

## Repository Architecture

| Feature          | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| **gitutils**     | Git aliases and workflow automation                      |
| **githooks**     | Dev environment setup: commitlint, prettier, lint-staged |
| **gitversion**   | Semantic versioning via GitVersion                       |
| **act**          | Local GitHub Actions via nektos/act                      |
| **pecl**         | PHP Extensions installer                                 |
| **larasets**     | Laravel-specific development utilities                   |
| **common-utils** | Shared scripts used by other features                    |
| **gateway**      | SSL certificate management for local development         |

Key files: `package.json`, `install.sh`, `.github/workflows/validate.yml`, `.github/workflows/release.yaml`, `stubs/`

## Core Development Commands

| Command                            | Purpose              | Duration                        |
| ---------------------------------- | -------------------- | ------------------------------- |
| `npm run lint`                     | Lint staged files    | 1-2s (empty), up to 15s (files) |
| `npm test`                         | Run tests            | <1s (no tests exist yet)        |
| `./install.sh -s`                  | Install stubs only   | 10-15s                          |
| `./install.sh -a`                  | Install all features | 15-20s                          |
| `./install.sh <feature>`           | Install one feature  | 5-10s                           |
| `npx tomgrv/devcontainer-features` | NPX install (cached) | ~2s                             |

**Always set command timeouts to 5+ minutes** to prevent premature cancellation.

## Essential Setup (Development/Testing Only — Do Not Commit)

```bash
npm install
npm install prettier-plugin-sh
find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;
find src/common-utils/ -type f -name "_*.sh" | while read file; do
    ln -sf "$file" src/common-utils/$(basename "$file" | sed 's/^_//;s/.sh$//')
done
ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh
```

## Critical Issues & Workarounds

| Issue                          | Cause                                             | Fix                                                                 |
| ------------------------------ | ------------------------------------------------- | ------------------------------------------------------------------- |
| `_zz_logs.sh: No such file`    | `install.sh` line 9 typo: `_zz_logs` vs `_zz_log` | `ln -sf src/common-utils/_zz_log.sh src/common-utils/_zz_logs.sh`   |
| `prettier-plugin-sh not found` | Plugin not installed                              | `npm install prettier-plugin-sh`                                    |
| `Permission denied` on scripts | Shell scripts not executable                      | `find src/common-utils/ -type f -name "_*.sh" -exec chmod +x {} \;` |
| `No writeable directory found` | Local run outside container                       | Normal — features are designed for devcontainer environments        |

## Testing Changes

```bash
mkdir /tmp/feature-test && cd /tmp/feature-test
git init
/workspaces/devcontainer-features/install.sh -s
ls -la .devcontainer/ .vscode/
```

## Pre-commit Validation

```bash
git add .
npm run lint # fixes linting issues on staged files
```
