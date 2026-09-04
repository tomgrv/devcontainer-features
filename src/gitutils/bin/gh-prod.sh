#!/bin/sh

# Trigger the release-prod GitHub Actions workflow.
exec gh workflow run release-prod.yml "$@"
