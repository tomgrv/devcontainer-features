<!-- @format -->

# Minikube Feature

This feature installs [Minikube](https://minikube.sigs.k8s.io/), a tool that makes it easy to run Kubernetes locally.

Minikube runs a single-node Kubernetes cluster inside a virtual machine on your laptop for users looking to try out Kubernetes or develop with it day-to-day.

More information about Minikube can be found on the [official Minikube GitHub repository](https://github.com/kubernetes/minikube).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/minikube:11": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add minikube
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add minikube
```

## Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-minikube
```

## GitLab CI

Each workflow above has a GitLab counterpart, deployed as a fragment merged into the repository's `.gitlab-ci.yml` (`stubs/_<workflow>...gitlab-ci.yml`). `tomgrv/actions` steps run through `zz-use -x tomgrv/actions/<name>`, with the action inputs set as environment variables.

- `validate-pr-docker`: `check-dockerfile` on merge requests.
