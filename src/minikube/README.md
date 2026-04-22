<!-- @format -->

# Minikube Feature

This feature installs [Minikube](https://minikube.sigs.k8s.io/), a tool that makes it easy to run Kubernetes locally.

Minikube runs a single-node Kubernetes cluster inside a virtual machine on your laptop for users looking to try out Kubernetes or develop with it day-to-day.

More information about Minikube can be found on the [official Minikube GitHub repository](https://github.com/kubernetes/minikube).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/minikube:5": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- minikube
```
