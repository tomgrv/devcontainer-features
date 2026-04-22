<!-- @format -->

# Nektos/Act

This feature provides a tool for running GitHub Actions locally.

More information about Act can be found on the [Act GitHub page](https://github.com/nektos/act).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/act:5": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- act
```

## Options

| Options Id | Description                    | Type   | Default Value |
| ---------- | ------------------------------ | ------ | ------------- |
| version    | The version of act to install. | string | master        |
