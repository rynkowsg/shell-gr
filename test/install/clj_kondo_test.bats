#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/../.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/bats_assert.bash"       # assert_equal
source "${_SHELL_GR_DIR}/lib/install/clj_kondo.bash" # GRI_CLJ_KONDO__install
source "${_SHELL_GR_DIR}/lib/temp.bash"              # temp_dir

test_listing_all_versions() { # @test
  output="$(GRI_CLJ_KONDO__list_all_versions)"
  echo "${output}"
  # the output should these sample versions
  assert_output --partial "2019.03.27-alpha" # first version
  assert_output --partial "2019.10.26"       # first non-alpha
  assert_output --partial "2024.03.13"       # latest (at time of writing the test)
}

test_getting_latest_stable_version() { # @test
  output="$(GRI_CLJ_KONDO__latest_stable)"
  echo "${output}"
  # received version should be in the format of "YYYY.MM.DD"
  assert_output --regexp "^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$"
}

test_installation() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "asdf-clj-kondo-download")"
  echo "Temp dir created: ${temp_install_dir}"
  GRI_CLJ_KONDO__INSTALL_TYPE="version" \
    GRI_CLJ_KONDO__INSTALL_VERSION="2024.02.12" \
    GRI_CLJ_KONDO__INSTALL_PATH="${temp_install_dir}" \
    GRI_CLJ_KONDO__install
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  assert_equal "clj-kondo v2024.02.12" "$("${temp_install_dir}/clj-kondo" --version)"
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}
