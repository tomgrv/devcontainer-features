#!/bin/sh

# Check if repository is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <github repository> [<directory>]"
  exit 1
fi

set -euo pipefail

# Get repository URL from argument
repo="${1}"

# Get directory from argument or use current directory
directory="${2:-.}"

# Get the repository host
host=$(echo "${repo}" | sed -E 's/https?:\/\/([^/]+)\/.*/\1/')

# Keep only the repository name
repo=$(echo "${repo}" | sed -E 's/.*github.com\/([^/]+)\/([^/]+).*/\1\/\2/')

# Create directory if it doesn't exist
mkdir -p "${directory}"

# Trace
echo "Repository: ${repo}"
echo "Directory: ${directory}"

# Download and extract repository per host
case $host in
    "gitlab.com")
        curl --location "https://gitlab.com/${repo}/-/archive/master/${repo}-master.tar.gz" | \
            tar --extract --ungzip --strip-components=1 --directory "${directory}"
        ;;
    "bitbucket.org")
        curl --location "https://bitbucket.org/${repo}/get/master.tar.gz" | \
            tar --extract --ungzip --strip-components=1 --directory "${directory}"
        ;;
    "github.com")
        curl --location "https://api.github.com/repos/${repo}/tarball" | \
            tar --extract --ungzip --strip-components=1 --directory "${directory}"
        ;;
    *)
        echo "Unsupported host: ${host}"
        exit 1
        ;;
esac

