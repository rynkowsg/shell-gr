#!/usr/bin/env bash

# Path Initialization
_GR_ERROR_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
_GR_ERROR_ROOT_DIR="$(cd "${_GR_ERROR_SCRIPT_DIR}/.." && pwd)"
_SHELL_GR_DIR="${SHELL_GR_DIR:-"${_GR_ERROR_ROOT_DIR}"}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/trap.bash" # add_on_exit

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
