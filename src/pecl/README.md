
# PECL Feature

This feature installs the PHP Extension Community Library (PECL) in the dev container. PECL is a repository for PHP extensions.

More information about PECL can be found on the [PECL website](https://pecl.php.net/).

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/pecl:1": {
        "extension": "zip"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | The version of GitVersion to install. | string | latest |

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
