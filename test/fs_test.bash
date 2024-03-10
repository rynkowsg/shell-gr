#!/usr/bin/env bats

# detect LIB_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
LIB_DIR="$(cd "${TEST_DIR}/../lib" || exit 1; pwd -P)"
# detect LIB_DIR - END

# shellcheck source=../lib/fs.bash
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
  result="$(normalized_path "~/test")"
  echo "result: ${result}"
  [ "${result}" == "${HOME}/test" ]
}
