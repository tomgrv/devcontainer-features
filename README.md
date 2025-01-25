<!-- @format -->

# Dev Container Features

This repository contains a collection of features that can be used to enhance the development experience in a [Visual Studio Code Dev Container](https://code.visualstudio.com/docs/remote/containers). The features are organized in separate folders and can be used individually.

## Installation

To install stubs in current repo

```sh
npx tomgrv/devcontainer-features -- --stubs
```

To install devcontainer feature(s) locally:

```sh
npx tomgrv/devcontainer-features -- gitutils
```

To setup a full dev environnement locally (repo + features)

```sh
npx tomgrv/devcontainer-features -- --all
```

## Features Overview

### GitVersion

The [GitVersion](./src/gitversion/) feature installs GitVersion in the dev container. GitVersion is a tool that calculates a version number based on the Git history. The version number is written to a file that can be used in the build process.

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

### GitUtils

The [GitUtils](./src/gitutils/) feature installs a collection of Git utilities in the dev container. The utilities are useful for automating Git workflows.

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
