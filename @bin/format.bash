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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/tool/format.bash" # format_with_env

main() {
  local format_cmd_type=$1
  local error=0
  format_with_env "${format_cmd_type}" bash < <(find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \)) || ((error += $?))
  format_with_env "${format_cmd_type}" bats < <(find "${ROOT_DIR}" -type f -name '*.bats') || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main "$@"
