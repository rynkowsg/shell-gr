#!/usr/bin/env bats

# detect LIB_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
LIB_DIR="$(cd "${TEST_DIR}/../lib" && pwd -P || exit 1)"
# detect LIB_DIR - END

# shellcheck source=lib/install_common.bash
source "${LIB_DIR}/install_common.bash"

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
