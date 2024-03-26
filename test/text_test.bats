#!/usr/bin/env bats
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# Path Initialization
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${TEST_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/text.bash"

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
