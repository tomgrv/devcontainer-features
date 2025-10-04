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

-   Installs specified common utilities such as jq and dos2unix.
-   Supports specifying additional utilities to install.

## Additional utilities

In addition to the specified utilities, some additional local utilities are also provided:

-   `zz_colors`: A set of color codes to source in your scripts for colored output.
-   `zz_log`: A utility to log messages with color
-   `zz_args`: A utility to parse command line arguments and display associated help messages in one go.

### Distribute zz_\* Utilities

The `zz_dist` utility allows you to copy all `zz_*` utilities from the devcontainer-installed location to a target directory. This is useful for maintaining a local copy of utilities in your project.

#### Usage

```bash
zz_dist [options]
```

#### Options

| Option     | Description                                                   |
| ---------- | ------------------------------------------------------------- |
| `-t <dir>` | Target directory (default: current directory or from config). |
| `-s <dir>` | Source directory (default: `/usr/local/share/common-utils`).  |

#### Configuration

The target directory can be configured in two ways:

1. **`.zz_dist` file**: Create a `.zz_dist` file in your project root with the target directory path on the first line.

```bash
echo "./scripts" > .zz_dist
```

2. **`package.json`**: Add a `config.zz_dist` entry to your `package.json`:

```json
{
	"config": {
		"zz_dist": "./scripts"
	}
}
```

If both are present, the `.zz_dist` file takes precedence. If neither is present, utilities are copied to the current directory.

#### Example

```bash
# Copy to current directory
zz_dist

# Copy to specific directory
zz_dist -t ./scripts

# Copy from custom source
zz_dist -s /custom/path -t ./scripts
```

### Validate JSON

The `validate-json` utility allows you to validate JSON files against a JSON schema. It supports the following features:

-   Validate against a schema from a local file or a URL.
-   Infer schema from the JSON Schema Store based on the file name.
-   Use a fallback schema if no schema is found locally or inferred.
-   Allow additional properties at the root level with the `-a` flag.
-   Cache schema validation maps for faster subsequent validations.

#### Usage

```bash
validate-json [options] <json>
```

#### Options

| Option      | Description                                                                                               |
| ----------- | --------------------------------------------------------------------------------------------------------- |
| `-a`        | Allow additional properties at the root level.                                                            |
| `-d`        | Enable debug output.                                                                                      |
| `-c`        | Allow caching of schema validation maps.                                                                  |
| `-f <file>` | Specify a fallback schema to use if none is found locally or inferred.                                    |
| `-l <path>` | Infer schema from a local folder based on the JSON file name (e.g., `x.y.json` → `<path>/y.schema.json`). |
| `-i`        | Infer schema from the JSON Schema Store if nothing is found locally.                                      |
| `-s <file>` | Specify a schema file or URL to use for validation.                                                       |

#### Example

```bash
validate-json -a -f fallback.schema.json -l ./schemas -i -s custom.schema.json example.json
```

### Normalize JSON

The `normalize-json` utility allows you to normalize JSON files based on a JSON schema. It supports the following features:

-   Validate the JSON file before normalization with the `validate-json` utility.
-   Normalize JSON keys according to the
    1 schema definition
    2 alphabetically

#### Usage

```bash
normalize-json [options] <json>
```

#### Options

| Option      | Description                                                                                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-w`        | Write the normalized JSON back to the original file.                                                                                                                |
| `-t <size>` | Specify the tab size for indentation.                                                                                                                               |
| `-c`        | Allow caching of schema validation maps.                                                                                                                            |
| `-a`        | Allow additional properties at the root level.                                                                                                                      |
| `-d`        | Enable debug output.                                                                                                                                                |
| `-f <file>` | Specify a fallback schema to use if none is found locally or inferred.                                                                                              |
| `-l <path>` | Infer schema from a local folder based on the JSON file name (e.g., `x.y.json` → `<path>/y.schema.json`). Use 'local' to target feature folder with default schemas |
| `-i`        | Infer schema from the JSON Schema Store if nothing is found locally.                                                                                                |
| `-s <file>` | Specify a schema file or URL to use for normalization.                                                                                                              |

#### Example

```bash
normalize-json -w -t 4 -f fallback.schema.json -l ./schemas -i -s custom.schema.json example.json
```

#### Lint-staged

You can use the `normalize-json` utility with `lint-staged` to normalize JSON files before committing them. To do this, add the following configuration to your `package.json`(see [githooks feature](../githooks/_lint-staged.package.json)).

```json
"lint-staged": {
    "*.json": [
        "normalize-json -c -w -a -i -t 4 -f local -l true"
    ]
}
```

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
