#!/usr/bin/env bats

# Path Initialization
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${TEST_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/error.bash" # run_with_unset_e

@test "run_with_unset_e - with state set -e" {
  # given
  set +e
  # when
  run_with_unset_e echo "Print something"
  # then
  read -r e_state < <(set +o | grep errexit)
  set -e # Required for Bats to detect assertion
  [ "${e_state}" == "set +o errexit" ]
}

@test "run_with_unset_e - with state set +e" {
  # given
  set -e
  # when
  run_with_unset_e echo "Print something"
  # then
  read -r e_state < <(set +o | grep errexit)
  set -e # Required for Bats to detect assertion
  [ "${e_state}" == "set -o errexit" ]
}
# `set -e` in the second function is technically not needed since
# `run_with_unset_e` recovers the state after the function call, but
# in case if there is a bug it could alter the state without recovery.
# This is for safety the assert works even if the function is broken.
