#!/usr/bin/env bats
# Copyright (c) 2024-2025. All rights reserved.
# License: MIT License
#

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/../.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/checksum.bash"

@test "verify_with_checksum_string_in_file - correct" {
  GR_CHECKSUM__ALGO=sha256 \
    GR_CHECKSUM__FILE_PATH="${_TEST_DIR}/resources/sample.txt" \
    GR_CHECKSUM__CHECKSUM_PATH="${_TEST_DIR}/resources/sample.txt.sha256" \
    verify_with_checksum_string_in_file
}
