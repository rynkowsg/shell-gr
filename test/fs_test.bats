#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/fs.bash"

@test "normalized_path - remove .." {
  result="$(normalized_path "/home/greg/src/test/../file")"
  [ "${result}" == "/home/greg/src/file" ]
}

@test "normalized_path - remove .. (from relative path)" {
  result="$(normalized_path "./src/test/../file")"
  echo "result: ${result}"
  [ "${result}" == "./src/file" ]
}

@test "normalized_path - remove ." {
  result="$(normalized_path "/home/user/./test")"
  echo "result: ${result}"
  [ "${result}" == "/home/user/test" ]
}

@test "normalized_path - remove . (from relative path)" {
  result="$(normalized_path "./directory/./test")"
  echo "result: ${result}"
  [ "${result}" == "./directory/test" ]
}

@test "normalized_path - remove consecutive /" {
  result="$(normalized_path "/home/user///test")"
  echo "result: ${result}"
  [ "${result}" == "/home/user/test" ]
}

@test "normalized_path - remove consecutive / - edge case" {
  result="$(normalized_path "///")"
  echo "result: ${result}"
  [ "${result}" == "/" ]
}

@test "normalized_path - resolve ~" {
  # shellcheck disable=SC2088
  result="$(normalized_path "~/test")"
  echo "result: ${result}"
  [ "${result}" == "${HOME}/test" ]
}
