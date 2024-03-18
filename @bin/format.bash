#!/usr/bin/env bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# Validates/corrects format
#
# Example:
#
#  - check:  @bin/format.bash check
#  - apply:  @bin/format.bash apply
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
SCRIPT_PATH="$([[ ! "${SCRIPT_PATH_1}" =~ ^(/bin/)?(ba)?sh$ ]] && readlink -f "${SCRIPT_PATH_1}" || exit 1)"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
SHELL_GR_DIR="${ROOT_DIR}"
# Library Sourcing
source "${SHELL_GR_DIR}/lib/tool/format.bash" # format_with_env

main() {
  local format_cmd_type=$1
  local error=0
  format_with_env "${format_cmd_type}" bash \
    < <(
      find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
        | sort
    ) \
    || ((error += $?))
  format_with_env "${format_cmd_type}" bats \
    < <(
      find "${ROOT_DIR}" -type f -name '*.bats' \
        | sort
    ) \
    || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main "$@"
