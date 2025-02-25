<!-- @format -->

# Common Utils

This feature provides common utilities for the devcontainer features.

## Installation

To install this feature, add it to your `devcontainer.json`:

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/common-utils:1": {
        "utils": "jq dos2unix"
    }
}
```

## Options

| Options Id | Description               | Type   | Default Value |
| ---------- | ------------------------- | ------ | ------------- |
| utils      | The utilities to install. | string | jq dos2unix   |

## Utilities

The following utilities are included by default:

-   `jq`
-   `dos2unix`

You can specify additional utilities to install by modifying the `utils` option in the `devcontainer.json` file.

## Customizations

The feature also includes the following VS Code customizations:

-   Extensions:

    -   `actboy168.tasks`
    -   `spmeesseman.vscode-taskexplorer`
    -   `gruntfuggly.triggertaskonsave`
    -   `natizyskunk.sftp`
    -   `formulahendry.auto-rename-tag`
    -   `formulahendry.auto-close-tag`
    -   `gruntfuggly.todo-tree`
    -   `foxundermoon.shell-format`
    -   `richie5um2.vscode-sort-json`

-   Settings:
    -   `editor.formatOnSave`: `true`
    -   `editor.formatOnPaste`: `true`
    -   `todo-tree.general.tags`: `["BUG", "HACK", "FIXME", "TODO", "XXX", "[ ]", "[x]", "NOTE"]`
    -   `editor.indentSize`: `"tabSize"`
    -   `editor.detectIndentation`: `true`
    -   `editor.tabSize`: `4`


## Functional Coverage

- Installs specified common utilities such as jq and dos2unix.
- Supports specifying additional utilities to install.

## Additional utilities

In addition to the specified utilities, some additional local utilities are also installed:

- `zz_args`: A utility to parse command line arguments and display associated help messages in one go.
- `zz_colors`: A set of color codes to source in your scripts for colored output.
- `normalize-json`: A utility to normalize JSON files based on a json schema.  Written in bash, using jq
    - Validate, filter & sort keys.
    - Retrieve schema from a local file or a URL. Can infer schema from json schema store.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
