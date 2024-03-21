#!/usr/bin/env bash

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
else
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ ^(/bin/)?(ba)?sh$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash" # NC, RED
source "${_SHELL_GR_DIR}/lib/trap.bash"  # add_on_exit

# generic
export ERROR_UNKNOWN=101
export ERROR_INVALID_FN_CALL=102
export ERROR_INVALID_STATE=103
# specific
export ERROR_COMMAND_DOES_NOT_EXIST=104

error_exit() {
  local msg="${1:-"Unknown Error"}"
  local code="${2:-${UNKNOWN_ERROR}}"
  printf "${RED}Error: %s${NC}\n" "${msg}" >&2
  exit "${code}"
}

assert_command_exist() {
  local command="$1"
  if ! command -v "${command}" &>/dev/null; then
    error_exit "'${command}' doesn't exist. Please install '${command}'." "${COMMAND_DONT_EXIST}"
  else
    printf "%s\n" "'${command}' detected..."
    printf "%s\n" ""
  fi
}

run_with_unset_e() {
  # Store the current 'set -e' state
  local set_e_disabled
  set_e_disabled=$(set +o | grep errexit)
  # Temporarily disable 'set -e'
  set +e
  # But on exit restore the original 'errexit' state
  add_on_exit eval "$set_e_disabled"
  # Run the passed command(s)
  "$@"
}
