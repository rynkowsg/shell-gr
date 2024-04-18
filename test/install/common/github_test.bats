#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/../../.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/bats_assert.bash"           # assert_equal
source "${_SHELL_GR_DIR}/lib/install/common/github.bash" # GRIC_GH_sort_versions

test_sorting_seperated_by_new_line() { # @test
  input=$(
    cat <<EOF
2024.04.12
2024.04.10
2024.04.09
2024.04.11
EOF
  )
  expected="2024.04.09 2024.04.10 2024.04.11 2024.04.12"
  output=$(echo "${input}" | GRIC_GH_sort_versions)
  echo "output:   '${output}'"
  echo "expected: '${expected}'"
  assert_equal "$output" "$expected"
}

test_sorting_seperated_by_space() { # @test
  input="2024.04.12 2024.04.10 2024.04.09 2024.04.11"
  expected="2024.04.09 2024.04.10 2024.04.11 2024.04.12"
  output=$(echo "${input}" | GRIC_GH_sort_versions)
  echo "output:   '${output}'"
  echo "expected: '${expected}'"
  assert_equal "$output" "$expected"
}
