#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash" # NC, RED

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

assert_not_empty() {
  local -r var_name="${1}"
  local -r var_value="${!var_name}"
  if [ -z "${var_value}" ]; then
    error_exit "${var_name} must not be empty"
  fi
}

run_with_unset_e() {
  # Check the current 'set -e' state
  local e_enabled
  if set +o | grep "set -o errexit" &>/dev/null; then
    e_enabled=1
  else
    e_enabled=0
  fi
  # If enabled, disable
  if [ ${e_enabled} -eq 1 ]; then
    set +e
  fi
  # Run the passed command(s)
  "$@"
  local -r res=$?
  # Enable 'errexit' if it was enabled
  if [ ${e_enabled} -eq 1 ]; then
    set -e
  fi
  # Return the result of the command
  return $res
}
