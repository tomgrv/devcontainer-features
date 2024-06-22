# Dev Container Features

This repository contains a collection of features that can be used to enhance the development experience in a [Visual Studio Code Dev Container](https://code.visualstudio.com/docs/remote/containers). The features are organized in separate folders and can be used individually.

## Features Overview

### GitVersion

The [GitVersion](./src/gitversion/) feature installs GitVersion in the dev container. GitVersion is a tool that calculates a version number based on the Git history. The version number is written to a file that can be used in the build process.

Originally, GitVersion was designed to be used in a CI/CD pipeline. However, it can also be used in a dev container to calculate the version number of the application.

More information about GitVersion can be found on the [GitVersion GitHub page](https://github.com/GitTools/GitVersion).

### GitUtils

The [GitUtils](./src/gitutils/) feature installs a collection of Git utilities in the dev container. The utilities are useful for automating Git workflows.

The following utilities are included: [./src/gitutils/alias.json](./src/gitutils/alias.json)

#### Interactive Utilities

- `git fixup` - Amend the specified commit with current changes and rebase

#### GitFlow

Additionnaly, the feature installs the [git-flow](https:://github.com/nvie/gitflow) extension and sets up the Git configuration to use it.

Shortcuts are also added to the `git` command to make it easier to use the `git-flow` commands:

- `git beta` is a shortcut for `git flow release start`
- `git hfix` is a shortcut for `git flow hotfix start`
- `git prod` is a shortcut for `git flow release finish` and `git flow hotfix finish`

Those shortcuts work in cunjunction with the `gitversion` utility to automatically update the version number of the application.

### Act

The [Act](./src/act/) feature installs the [nektos/act] tool in the dev container. Act is a tool that allows you to run GitHub Actions locally.

Originally, Act was designed to be used in a CI/CD pipeline. However, it can also be used in a dev container to test GitHub Actions locally.

More information about Act can be found on the [Act GitHub page](https://github.com/nektos/act).

### PECL

The [PECL](./src/pecl/) feature installs the PHP Extension Community Library (PECL) in the dev container. PECL is a repository for PHP extensions.

More information about PECL can be found on the [PECL website](https://pecl.php.net/).

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](./LICENSE).
