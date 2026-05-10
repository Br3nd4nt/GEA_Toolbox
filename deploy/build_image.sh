#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper to build the Docker image.
#
# Examples:
#   ./deploy/build_image.sh gea-demo:local
#   ./deploy/build_image.sh gea-demo:local --platform linux/amd64
#
# Note: If you are on ARM (Apple Silicon) you will likely need:
#   ./deploy/build_image.sh gea-demo:local --platform linux/amd64

TAG="${1:-gea-demo:local}"
shift || true

if [[ ! -d "dist/GEA_Demo" ]]; then
  echo "Missing dist/GEA_Demo. Run ./deploy/compile_demo.sh first (requires MATLAB + MATLAB Compiler)." >&2
  exit 2
fi

HOST_ARCH="$(uname -m || true)"
if [[ "${HOST_ARCH}" == "arm64" || "${HOST_ARCH}" == "aarch64" ]]; then
  # MathWorks MATLAB Runtime images are typically linux/amd64, so force amd64
  # when building on Apple Silicon / ARM.
  if ! docker buildx inspect >/dev/null 2>&1; then
    docker buildx create --use >/dev/null
  fi
  docker buildx build --platform linux/amd64 -t "${TAG}" --load "$@" .
else
  docker build -t "${TAG}" "$@" .
fi
