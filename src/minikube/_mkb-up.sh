#!/bin/sh

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Start minikube with embedded certs
minikube start --embed-certs

# Add certificates in .devcontainer/certs/*.pem to minikube's trusted certs as *.crt
for cert in /usr/local/share/ca-certificates/*.crt; do
    zz_log i "Adding local certificate $cert to minikube trusted certificates"
    docker cp "$cert" minikube:"$(minikube ssh -- "mktemp -u /usr/local/share/ca-certificates/XXXXXX.crt")"
done
minikube ssh "sudo update-ca-certificates"  

# Enable ingress addon
zz_log i "Enabling minikube ingress addon"
minikube addons enable ingress  
