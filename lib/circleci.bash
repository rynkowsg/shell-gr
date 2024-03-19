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
source "${_SHELL_GR_DIR}/lib/color.bash" # GREEN, NC

fix_home_in_old_images() {
  # Workaround old docker images with incorrect $HOME
  # check https://github.com/docker/docker/issues/2968 for details
  if [ -z "${HOME}" ] || [ "${HOME}" = "/" ]; then
    HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"
    export HOME
  fi
}

# Prints common debug info
# Usage:
#     print_common_debug_info "$@"
print_common_debug_info() {
  printf "${GREEN}%s${NC}\n" "Common debug info"
  bash --version
  # typical CLI debugging variables
  printf "\$0: %s\n" "$0"
  printf "\$@: %s\n" "$@"
  printf "BASH_SOURCE[0]: %s\n" "${BASH_SOURCE[0]}"
  printf "BASH_SOURCE[*]: %s\n" "${BASH_SOURCE[*]}"
  # other common
  printf "HOME: %s\n" "${HOME}"
  printf "PATH: %s\n" "${PATH}"
  printf "CIRCLECI: %s\n" "${CIRCLECI}"
  # shellpack related
  [ -n "${SCRIPT_PATH:-}" ] && printf "SCRIPT_PATH: %s\n" "${SCRIPT_PATH}"
  [ -n "${SCRIPT_DIR:-}" ] && printf "SCRIPT_DIR: %s\n" "${SCRIPT_DIR}"
  [ -n "${ROOT_DIR:-}" ] && printf "ROOT_DIR: %s\n" "${ROOT_DIR}"
  [ -n "${SHELL_GR_DIR:-}" ] && printf "SHELL_GR_DIR: %s\n" "${SHELL_GR_DIR}"
  [ -n "${_SHELL_GR_DIR:-}" ] && printf "_SHELL_GR_DIR: %s\n" "${_SHELL_GR_DIR}"
  printf "%s\n" ""
}
