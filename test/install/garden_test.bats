#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/../.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/bats_assert.bash"        # assert_equal
source "${_SHELL_GR_DIR}/lib/install/garden_cli.bash" # GRI_GARDEN_CLI__install, GRI_GARDEN_CLI__latest_stable, GRI_GARDEN_CLI__list_all_versions
source "${_SHELL_GR_DIR}/lib/temp.bash"               # temp_dir

# Releases for reference:
# https://github.com/nextjournal/garden-cli/releases

test_listing_all_versions() { # @test
  output="$(GRI_GARDEN_CLI__list_all_versions)"
  echo "${output}"
  # the output should these sample versions
  assert_output --partial "0.0.1" # first version
  assert_output --partial "0.1.0" # first minor version
  assert_output --partial "0.1.8" # latest (at time of writing the test)
}

test_getting_latest_stable_version() { # @test
  output="$(GRI_GARDEN_CLI__latest_stable)"
  echo "${output}"
  # received version should be in the format of "YYYY.MM.DD"
  assert_output --regexp "^[0-9]+\.[0-9]+\.[0-9]+$"
}

test_installation() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "garden_test__test_installation")"
  echo "Temp dir created: ${temp_install_dir}"
  GRI_GARDEN_CLI__INSTALL_TYPE="version" \
    GRI_GARDEN_CLI__INSTALL_VERSION="0.1.8" \
    GRI_GARDEN_CLI__INSTALL_PATH="${temp_install_dir}" \
    GRI_GARDEN_CLI__install
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  assert_equal "v0.1.8" "$("${temp_install_dir}/garden" version)"
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}
