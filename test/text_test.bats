#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/text.bash"

setup() {
  # Come up with a filepath for a temporary file. Don't create it.
  TEMP_FILE="$(mktemp -t "shell-gr_text_test-$(date +%Y%m%d_%H%M%S)-XXXXX" --dry-run)"
}

teardown() {
  rm -f "${TEMP_FILE}"
}

@test "append_if_not_exists - if file doesn't exist" {
  # given: file doesn't exist
  [ ! -f "${TEMP_FILE}" ]
  # when
  append_if_not_exists "test" "${TEMP_FILE}"
  # then
  result="$(cat "${TEMP_FILE}")"
  [ "${result}" == "test" ]
}

@test "append_if_not_exists - if file exist but value is not there" {
  # given
  touch "${TEMP_FILE}"
  # when
  append_if_not_exists "test" "${TEMP_FILE}"
  # then
  result="$(cat "${TEMP_FILE}")"
  [ "${result}" == "test" ]
}

@test "append_if_not_exists - if file exist but value is there" {
  # given
  echo "test" >"${TEMP_FILE}"
  # when
  append_if_not_exists "test" "${TEMP_FILE}"
  # then
  result="$(cat "${TEMP_FILE}")"
  [ "${result}" == "test" ]
}
