#!/usr/bin/env bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# Lint bash source files
#
# Example:
#
#     @bin/lint.bash
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/tool/lint.bash" # lint

main() {
  local error=0
  lint bash < <(find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \)) || ((error += $?))
  lint bats < <(find "${ROOT_DIR}" -type f -name '*.bats') || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main
