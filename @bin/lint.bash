#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

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
SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
SCRIPT_PATH="$([[ ! "${SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${SCRIPT_PATH_1}" || exit 1)"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
SHELL_GR_DIR="${ROOT_DIR}"
# Library Sourcing
source "${SHELL_GR_DIR}/lib/tool/lint.bash" # lint

main() {
  local error=0
  lint bash < <(find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) | sort) || ((error += $?))
  lint bats < <(find "${ROOT_DIR}" -type f -name '*.bats' | sort) || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main
