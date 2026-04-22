<!-- @format -->

# Gitversion Feature

This feature installs [GitVersion](https://gitversion.net/), a tool to help you generate a version number based on your git history.

Originally, GitVersion was designed to be used in a CI/CD pipeline. However, it can also be used in a dev container to calculate the version number of the application.

More information about GitVersion can be found on the [GitVersion GitHub page](https://github.com/GitTools/GitVersion).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gitversion:5": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- gitversion
```

## Options

| Options Id | Description                        | Type   | Default Value |
| ---------- | ---------------------------------- | ------ | ------------- |
| version    | The version of GitVersion to use.  | string | 6.5.1         |
