#!/usr/bin/env bash

_GR_LOG_SCRIPT_PATH="$([ -L "$0" ] && readlink "$0" || echo "$0")"
_GR_LOG_SCRIPT_DIR="$(cd "$(dirname "${_GR_LOG_SCRIPT_PATH}")" || exit 1; pwd -P)"
_GR_LOG_ROOT_DIR="$(cd "${_GR_LOG_SCRIPT_DIR}/.." && pwd)"
_SHELL_GR_DIR="${SHELL_GR_DIR:-"${_GR_LOG_ROOT_DIR}"}"

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
