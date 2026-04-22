<!-- @format -->

# Dev Container Features

This repository contains a collection of features that can be used to enhance the development experience in a [Visual Studio Code Dev Container](https://code.visualstudio.com/docs/remote/containers).

The features are organized in separate folders and can be used individually in a `devcontainer.json` file.

## Installation

The installation script can be run locally and/or in a devcontainer environment.

When run locally:

-   Features are installed in the local environment.
-   A `devcontainer.json` file is optionally created for the remote development experience.

```sh
npx tomgrv/devcontainer-features -h
```

#### To install only stubs

```sh
npx tomgrv/devcontainer-features -s
```

#### To install a specific devcontainer feature

```sh
npx tomgrv/devcontainer-features -- gitutils
```

#### To set up a full dev environment

```sh
npx tomgrv/devcontainer-features -a
```

## Features Overview

| Feature                             | Description                                             |
| ----------------------------------- | ------------------------------------------------------- |
| [GitUtils](#gitutils)               | Git aliases and workflow automation                     |
| [GitHooks](#githooks)               | Commit hooks: commitlint, prettier, lint-staged         |
| [GitVersion](#gitversion)           | Semantic versioning via GitVersion                      |
| [Act](#act)                         | Run GitHub Actions locally via nektos/act               |
| [PECL](#pecl)                       | PHP extension installer via PECL                        |
| [Larasets](#larasets)               | Laravel-specific development utilities                  |
| [Common Utils](#common-utils)       | Shared utilities used by other features                 |
| [Gateway](#gateway)                 | SSL certificate management for corporate networks       |
| [Minikube](#minikube)               | Local Kubernetes cluster via Minikube                   |

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
npx tomgrv/devcontainer-features -- gitutils
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
npx tomgrv/devcontainer-features -- githooks
```

---

### GitVersion

Installs [GitVersion](https://gitversion.net/) to calculate semantic version numbers from your Git history.

📖 [Full documentation](./src/gitversion/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitversion:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- gitversion
```

---

### Act

Installs [nektos/act](https://github.com/nektos/act) to run GitHub Actions locally inside the dev container.

📖 [Full documentation](./src/act/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/act:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- act
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
npx tomgrv/devcontainer-features -- pecl
```

---

### Larasets

Laravel-specific settings, shell utilities, Composer scripts, and VS Code extensions for Laravel development.

📖 [Full documentation](./src/larasets/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/larasets:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- larasets
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
npx tomgrv/devcontainer-features -- common-utils
```

---

### Gateway

Handles SSL inspection certificates for corporate network environments (e.g. Zscaler). Installs the root CA and wraps `curl` for transparent gateway authentication.

📖 [Full documentation](./src/gateway/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gateway:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- gateway
```

---

### Minikube

Installs [Minikube](https://minikube.sigs.k8s.io/) to run a single-node Kubernetes cluster locally inside the dev container.

📖 [Full documentation](./src/minikube/README.md)

#### Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/minikube:5": {}
}
```

#### Quick Install — console

```sh
npx tomgrv/devcontainer-features -- minikube
```

---

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](./LICENSE).
