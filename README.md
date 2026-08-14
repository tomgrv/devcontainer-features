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

Methods 2 and 3 both run `install.sh`, which behaves the same either way:

- **Outside a container** (a normal host, or `npx`/`curl` run from your machine): installs the tool itself (binaries, git config, etc.) and deploys the feature's stub files (`.devcontainer/`, `.github/`, editor config, ...) into the current project.
- **Inside a container** (Codespaces, an already-running devcontainer): skips the host-level tool install — that belongs in the container image build, i.e. method 1 — and only deploys the feature's stub files.

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

| Feature                       | Description                                                 |
| ----------------------------- | ----------------------------------------------------------- |
| [GitUtils](#gitutils)         | Git aliases and workflow automation                         |
| [GitHooks](#githooks)         | Commit hooks: commitlint, prettier, lint-staged             |
| [GitVersion](#gitversion)     | Semantic versioning via GitVersion                          |
| [Act](#act)                   | Run GitHub Actions locally via nektos/act                   |
| [PECL](#pecl)                 | PHP extension installer via PECL                            |
| [Larasets](#larasets)         | Laravel-specific development utilities                      |
| [Common Utils](#common-utils) | Shared utilities used by other features                     |
| [Gateway](#gateway)           | SSL certificate management for corporate networks           |
| [Minikube](#minikube)         | Local Kubernetes cluster via Minikube                       |
| [AI Coding](#ai-coding)       | Agent-agnostic AI coding skills + Claude Code GitHub Action |

---

### GitUtils

A collection of Git aliases, git-flow shortcuts, and interactive utilities for automating Git workflows.

📖 [Full documentation](./src/gitutils/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitutils:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add gitutils
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gitutils
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-gitutils
```

---

### GitHooks

Configures Git hooks in one step using commitlint, commitizen, lint-staged, prettier, and devmoji.

📖 [Full documentation](./src/githooks/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/githooks:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add githooks
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add githooks
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-githooks
```

---

### GitVersion

Installs [GitVersion](https://gitversion.net/) to calculate semantic version numbers from your Git history.

📖 [Full documentation](./src/gitversion/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitversion:6": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add gitversion
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gitversion
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-gitversion
```

---

### Act

Installs [nektos/act](https://github.com/nektos/act) to run GitHub Actions locally inside the dev container.

📖 [Full documentation](./src/act/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/act:6": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add act
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add act
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-act
```

---

### PECL

Installs PHP extensions from the [PHP Extension Community Library (PECL)](https://pecl.php.net/).

📖 [Full documentation](./src/pecl/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/pecl:5": {
        "extension": "zip"
    }
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add pecl
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add pecl
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-pecl
```

---

### Larasets

Laravel-specific settings, shell utilities, Composer scripts, and VS Code extensions for Laravel development.

📖 [Full documentation](./src/larasets/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/larasets:6": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add larasets
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add larasets
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-larasets
```

---

### Common Utils

Shared utilities (`jq`, `dos2unix`, JSON helpers, logging) used by other features in this collection.

📖 [Full documentation](./src/common-utils/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/common-utils:5": {
        "utils": "jq dos2unix"
    }
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add common-utils
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add common-utils
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-common-utils
```

---

### Gateway

Handles SSL inspection certificates for corporate network environments (e.g. Zscaler). Installs the root CA and wraps `curl` for transparent gateway authentication. Can also be installed on the **host** to make it ready for devcontainer creation behind the gateway.

📖 [Full documentation](./src/gateway/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gateway:7": {}
}
```

#### Quick Install — console (host)

```sh
npx tomgrv/devcontainer-features -- add gateway
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gateway
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-gateway
```

---

### Minikube

Installs [Minikube](https://minikube.sigs.k8s.io/) to run a single-node Kubernetes cluster locally inside the dev container.

📖 [Full documentation](./src/minikube/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/minikube:6": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add minikube
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add minikube
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-minikube
```

---

### AI Coding

Agent-agnostic AI coding skills (`.github/skills/`) plus the [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions) for `@claude` mentions on issues and pull requests.

📖 [Full documentation](./src/ai-coding/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/ai-coding:7": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add ai-coding
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add ai-coding
```

#### Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-ai-coding
```

---

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](./LICENSE).
