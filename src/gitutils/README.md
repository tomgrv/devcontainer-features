
# Git Utils

This feature provides a set of utilities for working with Git repositories.

The following aliases are included: [./alias.json](./src/gitutils/alias.json)

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitutils:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | The version of GitUtils to install. | string | latest |

## GitFlow

Additionnaly, the feature installs the [git-flow](https:://github.com/nvie/gitflow) extension and sets up the Git configuration to use it.

Shortcuts are also added to the `git` command to make it easier to use the `git-flow` commands:

- `git beta` is a shortcut for `git flow release start`
- `git hfix` is a shortcut for `git flow hotfix start`
- `git prod` is a shortcut for `git flow release finish` and `git flow hotfix finish`

Those shortcuts work in cunjunction with the `gitversion` utility to automatically update the version number of the application.

## Interactive Utilities

- `git fixup` - Amend the specified commit with current changes and rebase

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
