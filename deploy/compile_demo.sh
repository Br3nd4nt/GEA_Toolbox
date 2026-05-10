#!/usr/bin/env bash
set -euo pipefail

# Compile the CLI demos into a standalone executable (requires:
#  - MATLAB
#  - MATLAB Compiler
# This produces dist/GEA_Demo with the executable + CTF.

OUT_DIR="${1:-dist/GEA_Demo}"

MATLAB_BIN="${MATLAB_BIN:-}"
if [[ -z "${MATLAB_BIN}" ]]; then
  if command -v matlab >/dev/null 2>&1; then
    MATLAB_BIN="matlab"
  elif [[ -x "/Applications/MATLAB_R2024a.app/bin/matlab" ]]; then
    MATLAB_BIN="/Applications/MATLAB_R2024a.app/bin/matlab"
  fi
fi
if [[ -z "${MATLAB_BIN}" ]]; then
  echo "matlab not found. Set MATLAB_BIN=/path/to/matlab or add matlab to PATH." >&2
  exit 1
fi

"${MATLAB_BIN}" -batch "try, addpath(pwd); addpath(fullfile(pwd,'deploy')); compile_demo('outputDir','${OUT_DIR}'); catch ME, disp(getReport(ME,'extended')); exit(1); end; exit(0);"
