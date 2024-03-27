#!/usr/bin/env bats
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/install_common.bash"

@test "path_in_path - should find /usr/bin in PATH" {
  path_in_path "/usr/bin"
}

@test "path_in_path - shouldn't find unknown path in PATH" {
  bats_require_minimum_version 1.5.0
  run ! path_in_path "/usr/custom_bin"
}

@test "is_installed - common linux util 'cd' should be installed" {
  is_installed "cd"
}

@test "is_installed - non-existing should not be installed" {
  bats_require_minimum_version 1.5.0
  run ! is_installed "not-existing-command"
}
