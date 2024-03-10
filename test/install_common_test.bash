#!/usr/bin/env bats

# detect LIB_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
LIB_DIR="$(cd "${TEST_DIR}/../lib" || exit 1; pwd -P)"
# detect LIB_DIR - END

# shellcheck source=../lib/install_common.bash
source "${LIB_DIR}/install_common.bash"

@test "path_in_path - should find /usr/bin in PATH" {
  path_in_path "/usr/bin"
}

@test "path_in_path - shouldn't find unknown path in PATH" {
  ! path_in_path "/usr/custom_bin"
}

@test "is_installed - common linux util 'cd' should be installed" {
  is_installed "cd"
}

@test "is_installed - non-existing should not be installed``" {
  ! is_installed "not-existing-command"
}
