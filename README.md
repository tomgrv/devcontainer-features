<!-- @format -->

# Dev Container Features

This repository contains a collection of features that can be used to enhance the development experience in a [Visual Studio Code Dev Container](https://code.visualstudio.com/docs/remote/containers).

The features are organized in separate folders and can be used individually in a `devcontainer.json` file.

## Installation

Every feature in this repository can be installed three ways. Pick whichever fits where you're running:

1. **As a devcontainer feature** — declare it in `.devcontainer/devcontainer.json`; the Dev Containers CLI / VS Code builds it into the container image. Nothing to run locally. See each feature's own `## Quick Start — devcontainer.json` below.
2. **Console, via `npx`** — requires Node.js/npm on the machine you run it from (host or inside the container). Resolves this repo from GitHub and runs `install.sh`.
    ```sh
    npx tomgrv/devcontainer-features -h
    ```
3. **Console, via `curl`** — no Node.js/npm required. Downloads this repo to a temp directory, runs `install.sh`, and cleans up after itself:
    ```sh
    curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- -h
    ```
    Everything after `-s --` is forwarded to `install.sh` — same commands/targets as the `npx` form. Set `DEVCONTAINER_FEATURES_REF` to install from a different branch, tag, or commit.

Methods 2 and 3 both run `install.sh`, which behaves the same on a host and inside a container (Codespaces, an already-running devcontainer): it installs the tool itself (binaries, git config, package-manager installs where a feature needs one, ...) and deploys the feature's stub files (`.devcontainer/`, `.github/`, editor config, ...) into the current project. A handful of steps genuinely only make sense in one context or the other (e.g. gateway's host CA trust-store setup, or diverting `curl` only by default inside a container) — those scripts detect where they're running and adjust themselves; you don't need to.

#### To install only root stubs

```sh
npx tomgrv/devcontainer-features -- init
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- init
```

#### To install a specific devcontainer feature

```sh
npx tomgrv/devcontainer-features -- add gitutils
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gitutils
```

#### To set up a full dev environment

```sh
npx tomgrv/devcontainer-features -- add -a
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add -a
```

## Features Overview

Each row's console command is `add <feature>` (see [Installation](#installation)); the devcontainer.json id is `ghcr.io/tomgrv/devcontainer-features/<feature>:8`; the npm package is `@tomgrv/devcontainer-features-<feature>`.

| Feature                                      | `<feature>`    | Description                                                               |
| -------------------------------------------- | -------------- | ------------------------------------------------------------------------- |
| [GitUtils](./src/gitutils/README.md)         | `gitutils`     | Git aliases and workflow automation                                       |
| [GitHooks](./src/githooks/README.md)         | `githooks`     | Commit hooks: commitlint, prettier, lint-staged                           |
| [GitVersion](./src/gitversion/README.md)     | `gitversion`   | Semantic versioning via GitVersion                                        |
| [Act](./src/act/README.md)                   | `act`          | Run GitHub Actions locally via nektos/act                                 |
| [Larasets](./src/larasets/README.md)         | `larasets`     | Laravel-specific development utilities                                    |
| [Common Utils](./src/common-utils/README.md) | `common-utils` | Shared utilities (`jq`, `dos2unix`, ...) used by other features           |
| [Gateway](./src/gateway/README.md)           | `gateway`      | SSL inspection certs for corporate networks; also installable on the host |
| [Minikube](./src/minikube/README.md)         | `minikube`     | Local Kubernetes cluster via Minikube                                     |
| [AI Coding](./src/ai-coding/README.md)       | `ai-coding`    | Agent-agnostic AI coding skills + Claude Code GitHub Action               |

## MCP server for agents

An MCP server under [`.mcp/`](./.mcp/README.md) lets an agent list features, read their docs, and get the exact setup command — so it can bootstrap another repo's dev environment without crawling this README by hand.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](./LICENSE).
