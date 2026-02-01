<!-- @format -->

# Minikube Feature

This feature installs Minikube, a tool that makes it easy to run Kubernetes locally.

Minikube runs a single-node Kubernetes cluster inside a virtual machine on your laptop for users looking to try out Kubernetes or develop with it day-to-day.

More information about Minikube can be found on the [official Minikube GitHub repository]()

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/minikube:latest": {
    }
}
```

## Options

| Options Id | Description                           | Type   | Default Value |
| ---------- | ------------------------------------- | ------ | ------------- |
| version    | The version of GitVersion to install. | string | latest        |

## Functional Coverage

- Installs Minikube
- Configures Minikube to start on container creation

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
