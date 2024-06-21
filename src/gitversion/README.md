
# Gitversion Feature

This feature installs [GitVersion](https://gitversion.net/), a tool to help you generate a version number based on your git history.

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitversion:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | The version of GitVersion to install. | string | latest |
