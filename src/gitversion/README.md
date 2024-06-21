
# Gitversion Feature

This feature installs [GitVersion](https://gitversion.net/), a tool to help you generate a version number based on your git history.

Originally, GitVersion was designed to be used in a CI/CD pipeline. However, it can also be used in a dev container to calculate the version number of the application.

More information about GitVersion can be found on the [GitVersion GitHub page](https://github.com/GitTools/GitVersion).

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

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](./LICENSE).
