<!-- @format -->

# minikube

## Description

Use this feature when an agent needs local Kubernetes capabilities inside the dev environment using Minikube.

## Commands

- `minikube start` - Start local Minikube cluster.
- `minikube stop` - Stop local Minikube cluster.
- `minikube status` - Check Minikube and Kubernetes component status.
- `mkb` - Run feature-level Minikube helper wrapper.
- `mkb-up` - Start Minikube using repository helper defaults.
- `mkb-preload` - Preload container images used by local workflows.
- `mkb-pds` - Run project-defined Minikube bootstrap/support flow.

## Use For

- Local Kubernetes cluster setup for development/testing.
- Running and validating Kubernetes manifests in a single-node cluster.
- Reproducing k8s workflow issues without remote infrastructure.

## Do Not Use For

- Production cluster provisioning.
- PHP/Laravel-specific tooling concerns.

## Agent Guidance

- Verify Minikube runtime prerequisites before starting cluster actions.
- Keep manifests and tests targeted to local/dev constraints.
- Prefer incremental validation (namespace/app) before full environment rollout.
