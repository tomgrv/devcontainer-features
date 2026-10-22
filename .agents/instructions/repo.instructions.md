---
applyTo: '**'
---

<!-- @format -->

# Devcontainer Features Repository

This repository contains 10 devcontainer features installed via `install.sh` or `npx tomgrv/devcontainer-features`.

## Repository Architecture

| Feature          | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| **gitutils**     | Git aliases and workflow automation                      |
| **githooks**     | Dev environment setup: commitlint, prettier, lint-staged |
| **gitversion**   | Semantic versioning via GitVersion                       |
| **act**          | Local GitHub Actions via nektos/act                      |
| **larasets**     | Laravel-specific development utilities                   |
| **common-utils** | Shared scripts used by other features                    |
| **gateway**      | SSL certificate management for local development         |
| **ai-coding**    | AI tooling stubs: skills, instructions, harness          |
| **scripting**    | Shared scripting entrypoints                             |
| **minikube**     | Local Kubernetes via minikube                            |

Key files: `package.json`, `install.sh`, `.github/workflows/validate.yml`, `.github/workflows/release.yaml`, `stubs/`

## Core Development Commands

| Command                            | Purpose              | Duration                        |
| ---------------------------------- | -------------------- | ------------------------------- |
| `npm run lint`                     | Lint staged files    | 1-2s (empty), up to 15s (files) |
| `npm test`                         | Run bats suites      | seconds (`bats -r tests src`)   |
| `./install.sh -s`                  | Install stubs only   | 10-15s                          |
| `./install.sh -a`                  | Install all features | 15-20s                          |
| `./install.sh <feature>`           | Install one feature  | 5-10s                           |
| `npx tomgrv/devcontainer-features` | NPX install (cached) | ~2s                             |

**Always set command timeouts to 5+ minutes** to prevent premature cancellation.

## Essential Setup (Development/Testing Only — Do Not Commit)

```bash
npm install
npm install prettier-plugin-sh
```

The `zz-*` helper scripts no longer live in `src/common-utils/bin/`: `src/common-utils/install.sh` fetches them from [`tomgrv/scripts`](https://github.com/tomgrv/scripts) via `zz-use` (pinned by `ZZ_ORIGIN_REF`).

## Installing Packages in a Feature

Never write inline `apt-get`/`apk`/`sudo` branching. Use the shared helper:

```sh
zz-use zz-install
zz-install git-flow apk=gitflow-avh dnf=gitflow brew=git-flow-avh
```

See `src/gitutils/install-gitflow.sh`.

## Critical Issues & Workarounds

| Issue                          | Cause                       | Fix                                                          |
| ------------------------------ | --------------------------- | ------------------------------------------------------------ |
| `prettier-plugin-sh not found` | Plugin not installed        | `npm install prettier-plugin-sh`                             |
| `No writeable directory found` | Local run outside container | Normal — features are designed for devcontainer environments |

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
