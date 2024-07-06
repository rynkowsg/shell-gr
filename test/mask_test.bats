#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/bats_assert.bash" # assert_equal
source "${_SHELL_GR_DIR}/lib/mask.bash"        # mask

mask_string() { # @test
  on_input="test"
  expected="****"
  result="$(mask "${on_input}")"
  assert_equal "${expected}" "${result}"
}

mask_empty() { # @test
  on_input=""
  expected=""
  result="$(mask "${on_input}")"
  assert_equal "${expected}" "${result}"
}

mask_number() { # @test
  on_input=1
  expected="*"
  result="$(mask "${on_input}")"
  assert_equal "${expected}" "${result}"
}
