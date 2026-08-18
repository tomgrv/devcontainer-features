#!/bin/sh

# Navigate to the repository root
cd "$(git rev-parse --show-toplevel)" >/dev/null

# Function to print help and manage arguments
eval $(
    zz_args "Preload images from specified helm chart" $0 "$@" <<-help
			- chart     chart      helm chart (default is 'src')
	help
)

# Preload helm chart images into minikube
for image in $(helm template ${chart:-src} | grep -oP 'image:\s*\K[^"]+' | sort -u); do
  zz_log i "Preloading image $image into minikube"
  minikube image pull "$image"
done
