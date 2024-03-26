#!/usr/bin/env bats
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# Path Initialization
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${TEST_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/fs.bash"

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
