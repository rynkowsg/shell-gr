#!/usr/bin/env bash

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/tool/lint.bash" # lint

main() {
  local error=0
  find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) | grep -v -E '(.shellpack_deps|/gen/)' | lint bash || ((error += $?))
  find "${ROOT_DIR}" -type f -name '*.bats' | lint bats || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main
