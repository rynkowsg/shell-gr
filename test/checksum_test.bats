#!/usr/bin/env bats
# Copyright (c) 2025 Greg Rynkowski. All rights reserved.
# License: MIT License

# Require at least Bats 1.5.0 for run flags
bats_require_minimum_version 1.5.0

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/checksum.bash"

setup() {
  TMP_FILE="$(mktemp -t "shell-gr_checksum_test-$(date +%Y%m%d_%H%M%S)-XXXXX" --dry-run)"
  cat <<-EOF >"${TMP_FILE}"
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
EOF
  TMP_FILE_MD5="7873b606429a70284d63f0674e6787bc"
  TMP_FILE_SHA1="cd92a5f9e8ed40f3f2b5733440d407e5dc6461fd"
  TMP_FILE_SHA256="d7215606b073b0c4149f21a429db6b344a5cc18279043ca2baa4b819f7002a3d"
  TMP_FILE_SHA512="c84d745931b92e67c85822cef086ba18d2ad8396392831a2b8bdfc614395a33b3ad215b7828c40fea621e692115de1d63d4f6131519dd1211e9d0e85fc4e42ff"
}

teardown() {
  rm -f "${TMP_FILE}"
}

# test each checksum tool separately

@test "verify_with_openssl" {
  command -v openssl >/dev/null || skip "openssl not installed"

  declare -A correct_checksums=(
    [md5]="${TMP_FILE_MD5}"
    [sha1]="${TMP_FILE_SHA1}"
    [sha256]="${TMP_FILE_SHA256}"
    [sha512]="${TMP_FILE_SHA512}"
  )

  for algo in "${!correct_checksums[@]}"; do
    echo "Testing ${algo} (correct checksum)"
    GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo}]}" \
      GR_CHECKSUM__ALGO="${algo}" \
      verify_with_openssl

    echo "Testing ${algo} (incorrect checksum)"
    run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo}]}-incorrect" \
      GR_CHECKSUM__ALGO="${algo}" \
      verify_with_openssl
  done
}

@test "verify_with_shasum - shasum" {
  command -v shasum >/dev/null || skip "shasum not installed"

  declare -A correct_checksums=(
    [1]="${TMP_FILE_SHA1}"
    [256]="${TMP_FILE_SHA256}"
    [512]="${TMP_FILE_SHA512}"
  )

  for algo_ver in "${!correct_checksums[@]}"; do
    echo "Testing ${algo_ver} (correct checksum)"
    GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo_ver}]}" \
      GR_CHECKSUM__ALGO="${algo_ver}" \
      GR_CHECKSUM__SHA_CMD_FMT="shasum -a %s" \
      verify_with_shasum

    echo "Testing ${algo_ver} (incorrect checksum)"
    run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo_ver}]}-incorrect" \
      GR_CHECKSUM__ALGO="${algo_ver}" \
      GR_CHECKSUM__SHA_CMD_FMT="shasum -a %s" \
      verify_with_shasum
  done
}

@test "verify_with_shasum - sha*sum" {
  command -v sha256sum >/dev/null || skip "sha256sum not installed"

  declare -A correct_checksums=(
    [1]="${TMP_FILE_SHA1}"
    [256]="${TMP_FILE_SHA256}"
    [512]="${TMP_FILE_SHA512}"
  )

  for algo_ver in "${!correct_checksums[@]}"; do
    echo "Testing ${algo_ver} (correct checksum)"
    GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo_ver}]}" \
      GR_CHECKSUM__ALGO="sha${algo_ver}" \
      GR_CHECKSUM__SHA_CMD_FMT="sha%ssum" \
      verify_with_shasum

    echo "Testing ${algo_ver} (incorrect checksum)"
    run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo_ver}]}-incorrect" \
      GR_CHECKSUM__ALGO="sha${algo_ver}" \
      GR_CHECKSUM__SHA_CMD_FMT="sha%ssum" \
      verify_with_shasum
  done
}

@test "verify_with_shasum - gsha*sum" {
  command -v gsha256sum >/dev/null || skip "gsha256sum not installed"

  declare -A correct_checksums=(
    [1]="${TMP_FILE_SHA1}"
    [256]="${TMP_FILE_SHA256}"
    [512]="${TMP_FILE_SHA512}"
  )

  for algo_ver in "${!correct_checksums[@]}"; do
    echo "Testing ${algo_ver} (correct checksum)"
    GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo_ver}]}" \
      GR_CHECKSUM__ALGO="sha${algo_ver}" \
      GR_CHECKSUM__SHA_CMD_FMT="gsha%ssum" \
      verify_with_shasum

    echo "Testing ${algo_ver} (incorrect checksum)"
    run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo_ver}]}-incorrect" \
      GR_CHECKSUM__ALGO="sha${algo_ver}" \
      GR_CHECKSUM__SHA_CMD_FMT="gsha%ssum" \
      verify_with_shasum
  done
}

@test "verify_with_md5" {
  command -v md5 >/dev/null || skip "md5 not installed"
  GR_CHECKSUM__FILE_PATH="${TMP_FILE}" GR_CHECKSUM__CHECKSUM="${TMP_FILE_MD5}" verify_with_md5
  run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" GR_CHECKSUM__CHECKSUM="${TMP_FILE_MD5}-incorrect" verify_with_md5
}

@test "verify_with_md5sum" {
  command -v md5sum >/dev/null || skip "md5sum not installed"
  GR_CHECKSUM__FILE_PATH="${TMP_FILE}" GR_CHECKSUM__CHECKSUM="${TMP_FILE_MD5}" verify_with_md5sum
  run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" GR_CHECKSUM__CHECKSUM="${TMP_FILE_MD5}-incorrect" verify_with_md5sum
}

# test the methods that dispatches checks (uses the first tool available for the job)

@test "verify_with_checksum_string" {
  declare -A correct_checksums=(
    [md5]="${TMP_FILE_MD5}"
    [sha1]="${TMP_FILE_SHA1}"
    [sha256]="${TMP_FILE_SHA256}"
    [sha512]="${TMP_FILE_SHA512}"
  )

  for algo in "${!correct_checksums[@]}"; do
    echo "Testing ${algo} (correct checksum)"
    GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo}]}" \
      GR_CHECKSUM__ALGO="${algo}" \
      verify_with_checksum_string

    echo "Testing ${algo} (incorrect checksum)"
    run ! GR_CHECKSUM__FILE_PATH="${TMP_FILE}" \
      GR_CHECKSUM__CHECKSUM="${correct_checksums[${algo}]}-incorrect" \
      GR_CHECKSUM__ALGO="${algo}" \
      verify_with_checksum_string
  done
}
