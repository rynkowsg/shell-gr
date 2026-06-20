#!/usr/bin/env bats
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/path.bash"

@test "path_prepend - prepend to non-empty PATH" {
  result="$(path_prepend "/usr/bin:/bin" "/usr/local/bin")"
  [ "${result}" == "/usr/local/bin:/usr/bin:/bin" ]
}

@test "path_prepend - prepend to empty PATH" {
  result="$(path_prepend "" "/usr/local/bin")"
  [ "${result}" == "/usr/local/bin:" ]
}

@test "path_prepend - dir already present is a no-op" {
  result="$(path_prepend "/usr/bin:/bin" "/usr/bin")"
  [ "${result}" == "/usr/bin:/bin" ]
}

@test "path_prepend - dir present in the middle is a no-op" {
  result="$(path_prepend "/usr/bin:/usr/local/bin:/bin" "/usr/local/bin")"
  [ "${result}" == "/usr/bin:/usr/local/bin:/bin" ]
}

@test "path_prepend - dir present at the end is a no-op" {
  result="$(path_prepend "/usr/bin:/bin" "/bin")"
  [ "${result}" == "/usr/bin:/bin" ]
}

@test "path_prepend - prefix-only match is not treated as present" {
  result="$(path_prepend "/usr/bin:/bin" "/usr")"
  [ "${result}" == "/usr:/usr/bin:/bin" ]
}
