#!/usr/bin/env bash
set -euo pipefail

DEMO="${1:-minimal}"
shift || true

# Find the compiled executable produced by compiler.build.standaloneApplication.
# Common layouts include:
#   app/GEA_demo_runner
#   app/for_redistribution_files_only/GEA_demo_runner
#   app/for_testing/GEA_demo_runner
find_exe() {
  local root="$1"
  local name="$2"

  if [[ -x "${root}/${name}" ]]; then
    echo "${root}/${name}"
    return 0
  fi

  local hit
  hit="$(find "${root}" -maxdepth 4 -type f -name "${name}" -perm -111 2>/dev/null | head -n 1 || true)"
  if [[ -n "${hit}" ]]; then
    echo "${hit}"
    return 0
  fi
  return 1
}

EXE="$(find_exe "/opt/gea_demo/app" "GEA_demo_runner" || true)"
if [[ -n "${EXE}" && "${EXE}" == *".app/"* ]]; then
  echo "Found macOS app bundle executable path inside the image:" >&2
  echo "  ${EXE}" >&2
  echo "This container requires a Linux-compiled executable." >&2
  echo "Compile the demo on Linux (same MATLAB release) and rebuild the image." >&2
  exit 3
fi
if [[ -z "${EXE}" ]]; then
  # Common failure mode: building on macOS produces a .app bundle, which is not runnable in Linux containers.
  if find "/opt/gea_demo/app" -maxdepth 4 -type d -name "GEA_demo_runner.app" >/dev/null 2>&1; then
    echo "Found macOS app bundle (GEA_demo_runner.app) inside the image." >&2
    echo "This container requires a Linux-compiled executable." >&2
    echo "Compile the demo on Linux (same MATLAB release) to produce a Linux binary, then rebuild the image." >&2
    exit 3
  fi
fi
if [[ -z "${EXE}" ]]; then
  echo "Could not find compiled executable 'GEA_demo_runner' under /opt/gea_demo/app" >&2
  echo "Did you run ./deploy/compile_demo.sh to generate dist/GEA_Demo before building the image?" >&2
  exit 2
fi

exec "${EXE}" "${DEMO}" "$@"
