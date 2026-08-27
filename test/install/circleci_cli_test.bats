#!/usr/bin/env bats
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/../.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/bats_assert.bash"          # assert_equal
source "${_SHELL_GR_DIR}/lib/install/circleci_cli.bash" # GRI_CIRCLECI_CLI__install, GRI_CIRCLECI_CLI__latest_stable, GRI_CIRCLECI_CLI__list_all_versions
source "${_SHELL_GR_DIR}/lib/temp.bash"                 # temp_dir

# Releases for reference:
# https://github.com/CircleCI-Public/circleci-cli/releases

test_listing_all_versions() { # @test
  output="$(GRI_CIRCLECI_CLI__list_all_versions)"
  echo "${output}"
  # the output should these sample versions
  assert_output --partial "0.1.6"     # first version
  assert_output --partial "0.1.33163" # a release with the old archive layout
  assert_output --partial "1.0.47611" # a release with the new archive layout
}

test_listing_all_versions_skips_tags_that_are_not_versions() { # @test
  output="$(GRI_CIRCLECI_CLI__list_all_versions)"
  echo "${output}"
  # the repo tags a separate library as "clikit/vX.Y.Z" and carries one-off tags,
  # neither of which is a version of this tool
  refute_output --partial "clikit"
  refute_output --partial "test-abraham"
}

test_getting_latest_stable_version() { # @test
  output="$(GRI_CIRCLECI_CLI__latest_stable)"
  echo "${output}"
  # received version should be in the format of "MAJOR.MINOR.PATCH"
  assert_output --regexp "^[0-9]+\.[0-9]+\.[0-9]+$"
}

test_installation() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "circleci_cli_test__test_installation")"
  echo "Temp dir created: ${temp_install_dir}"
  GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.33163" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${temp_install_dir}" \
    GRI_CIRCLECI_CLI__install
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  # `circleci version` prints "<version>+<commit> (<source>)", so match the version part
  output="$("${temp_install_dir}/circleci" version)"
  assert_output --partial "0.1.33163"
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}
