#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/error.bash" # run_with_unset_e

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
