#!/usr/bin/env bash

# Path Initialization
_GR_LOG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
_GR_LOG_ROOT_DIR="$(cd "${_GR_LOG_SCRIPT_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${SHELL_GR_DIR:-"${_GR_LOG_ROOT_DIR}"}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash"

error() {
  printf "${RED}%s${NC}\n" "${1}"
}

warning() {
  printf "${YELLOW}%s${NC}\n" "${1}"
}

info() {
  printf "%s\n" "${1}"
}

debug() {
  printf "%s\n" "${1}"
}
