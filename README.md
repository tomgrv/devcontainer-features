<!-- @format -->

# Dev Container Features

This repository contains a collection of features that can be used to enhance the development experience in a [Visual Studio Code Dev Container](https://code.visualstudio.com/docs/remote/containers).

The features are organized in separate folders and can be used individually in a `devcontainer.json` file

## 🚀 Multi-workspace Release Automation

This repository includes an automated release workflow that handles version management for multiple workspaces (devcontainer features) according to semantic versioning and conventional commit standards.

**Key Features:**
- ✅ **Workspace Change Detection**: Automatically detects which workspaces have been modified
- ✅ **Conventional Commit Analysis**: Analyzes commit messages for semantic version bumps  
- ✅ **Gitflow Integration**: Creates release branches following gitflow conventions
- ✅ **Individual Version Management**: Updates only the workspaces that have changed
- ✅ **Automated Pull Requests**: Creates PR to merge release branch into main

For detailed documentation, see: [Multi-workspace Release Documentation](./docs/multi-workspace-release.md)

**Quick Start:**
1. Go to **Actions** tab in GitHub
2. Select **"Multi-workspace Release Automation"**
3. Click **"Run workflow"** (optionally enable dry run mode for testing)

## Installation

Installation script can be run locally and/or in devcontainer environnement

When run locally:
- features are installed in local environment.
- a `devcontainer.json` file is eventually created for remote development experience.

```sh
npx tomgrv/devcontainer-features -h
```

#### To install only stubs

```sh
npx tomgrv/devcontainer-features -s
```

#### To install a specific devcontainer feature(s) 

```sh
npx tomgrv/devcontainer-features -- gitutils
```

#### To setup a full dev environnement with 

- [GitUtils](./src/gitutils/)
- [GitHooks](./src/githooks/)

```sh
npx tomgrv/devcontainer-features -a
```

## Features Overview

### GitUtils

The [GitUtils](./src/gitutils/) feature installs a collection of Git utilities in the dev container. The utilities are useful for automating Git workflows.

### GitHooks

Configure developpement environnement in one step in conjunction with following packages:

-   @commitlint/cli
-   @commitlint/config-conventional
-   @commitlint/core
-   @commitlint/cz-commitlint
-   commitizen
-   conventional-changelog-cli
-   devmoji
-   git-precommit-checks
-   lint-staged
-   prettier
-   sort-package-json

### GitVersion

The [GitVersion](./src/gitversion/) feature installs GitVersion in the dev container. GitVersion is a tool that calculates a version number based on the Git history. The version number is written to a file that can be used in the build process.

### Act

The [Act](./src/act/) feature installs the [nektos/act] tool in the dev container. Act is a tool that allows you to run GitHub Actions locally.

More information about Act can be found on the [Act GitHub page](https://github.com/nektos/act).

### PECL

The [PECL](./src/pecl/) feature installs the PHP Extension Community Library (PECL) in the dev container. PECL is a repository for PHP extensions.

More information about PECL can be found on the [PECL website](https://pecl.php.net/).

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](./LICENSE).
