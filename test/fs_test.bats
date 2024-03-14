#!/usr/bin/env bats

# detect LIB_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
LIB_DIR="$(cd "${TEST_DIR}/../lib" && pwd -P || exit 1)"
# detect LIB_DIR - END

# shellcheck source=lib/fs.bash
source "${LIB_DIR}/fs.bash"

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
