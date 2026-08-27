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
  # the output should have these sample versions
  # the selected versions have an asset for every platform, so the test passes on any machine
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

test_listing_all_versions_skips_tags_without_release() { # @test
  output="$(GRI_CIRCLECI_CLI__list_all_versions)"
  echo "${output}"
  # The versions come out space separated, so match whole entries. A plain
  # substring would find "0.1.998" inside "0.1.9988", which is a real release.
  # these are tagged but were never released, so there is nothing to install
  refute_output --regexp "(^| )0\.1\.168( |$)"
  refute_output --regexp "(^| )0\.1\.998( |$)"
  refute_output --regexp "(^| )0\.1\.6371( |$)"
  refute_output --regexp "(^| )0\.1\.23479( |$)"
  refute_output --regexp "(^| )0\.1\.47632( |$)"
  # the releases surrounding them are still listed, again selected to have an asset for every platform
  assert_output --regexp "(^| )0\.1\.38646( |$)"
  assert_output --regexp "(^| )0\.1\.47860( |$)"
}

# A release does not have to carry an asset for every platform and architecture,
# see the table next to GRI_CIRCLECI_CLI__has_asset. The versions below are the
# boundaries of that table plus the releases that skipped a single build.
VERSIONS_ACROSS_ASSET_BOUNDARIES=(
  "0.1.6"
  "0.1.1563"
  "0.1.4029"
  "0.1.6640"
  "0.1.17522"
  "0.1.17554"
  "0.1.28363"
  "0.1.28391"
  "0.1.28434"
  "0.1.28528"
  "0.1.47860"
  "1.0.47611"
)

test_keeping_versions_with_an_asset_for_darwin_amd64() { # @test
  output="$(printf "%s\n" "${VERSIONS_ACROSS_ASSET_BOUNDARIES[@]}" | GRI_CIRCLECI_CLI__keep_versions_with_asset "darwin" "amd64")"
  echo "${output}"
  # 0.1.6640 is the only release without a darwin/amd64 asset
  assert_equal "$(printf "%s\n" "0.1.6" "0.1.1563" "0.1.4029" "0.1.17522" "0.1.17554" "0.1.28363" "0.1.28391" "0.1.28434" "0.1.28528" "0.1.47860" "1.0.47611")" "${output}"
}

test_keeping_versions_with_an_asset_for_darwin_arm64() { # @test
  output="$(printf "%s\n" "${VERSIONS_ACROSS_ASSET_BOUNDARIES[@]}" | GRI_CIRCLECI_CLI__keep_versions_with_asset "darwin" "arm64")"
  echo "${output}"
  # darwin/arm64 starts at 0.1.28363, then 0.1.28391 and 0.1.28434 skip it
  assert_equal "$(printf "%s\n" "0.1.28363" "0.1.28528" "0.1.47860" "1.0.47611")" "${output}"
}

test_keeping_versions_with_an_asset_for_linux_amd64() { # @test
  output="$(printf "%s\n" "${VERSIONS_ACROSS_ASSET_BOUNDARIES[@]}" | GRI_CIRCLECI_CLI__keep_versions_with_asset "linux" "amd64")"
  echo "${output}"
  # 0.1.1563 and 0.1.4029 are the only releases without a linux/amd64 asset
  assert_equal "$(printf "%s\n" "0.1.6" "0.1.6640" "0.1.17522" "0.1.17554" "0.1.28363" "0.1.28391" "0.1.28434" "0.1.28528" "0.1.47860" "1.0.47611")" "${output}"
}

test_keeping_versions_with_an_asset_for_linux_arm64() { # @test
  output="$(printf "%s\n" "${VERSIONS_ACROSS_ASSET_BOUNDARIES[@]}" | GRI_CIRCLECI_CLI__keep_versions_with_asset "linux" "arm64")"
  echo "${output}"
  # linux/arm64 starts at 0.1.17554 and no release after it skips the build
  assert_equal "$(printf "%s\n" "0.1.17554" "0.1.28363" "0.1.28391" "0.1.28434" "0.1.28528" "0.1.47860" "1.0.47611")" "${output}"
}

test_getting_latest_stable_version() { # @test
  output="$(GRI_CIRCLECI_CLI__latest_stable)"
  echo "${output}"
  # received version should be in the format of "MAJOR.MINOR.PATCH"
  assert_output --regexp "^[0-9]+\.[0-9]+\.[0-9]+$"
}

test_installation_of_release_with_wrapped_archive() { # @test
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

# 0.1.6 is the only release whose assets are named "cli_*" instead of
# "circleci-cli_*".
test_installation_of_first_release() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "circleci_cli_test__test_installation_first")"
  echo "Temp dir created: ${temp_install_dir}"
  # `run` keeps a failed install from taking the whole bats run down with it,
  # because `fail` exits the process
  run env \
    GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.6" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${temp_install_dir}" \
    bash -c "source '${_SHELL_GR_DIR}/lib/install/circleci_cli.bash'; GRI_CIRCLECI_CLI__install"
  echo "${output}"
  assert_equal 0 "${status}"
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  # see the note on running old binaries in the early flat archive test
  assert [ -x "${temp_install_dir}/circleci" ]
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}

# Up to 0.1.160 the archive carries the binary as "circleci-beta", which the
# plugin installs as "circleci" so that the command name stays the same across
# versions.
test_installation_of_release_with_beta_binary() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "circleci_cli_test__test_installation_beta")"
  echo "Temp dir created: ${temp_install_dir}"
  # `run` keeps a failed install from taking the whole bats run down with it,
  # because `fail` exits the process
  run env \
    GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.19" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${temp_install_dir}" \
    bash -c "source '${_SHELL_GR_DIR}/lib/install/circleci_cli.bash'; GRI_CIRCLECI_CLI__install"
  echo "${output}"
  assert_equal 0 "${status}"
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  # see the note on running old binaries in the early flat archive test
  assert [ -x "${temp_install_dir}/circleci" ]
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}

# Up to 0.1.386 the archive keeps its files at the root, the same as the 1.0 line
# does much later.
test_installation_of_release_with_early_flat_archive() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "circleci_cli_test__test_installation_early_flat")"
  echo "Temp dir created: ${temp_install_dir}"
  # `run` keeps a failed install from taking the whole bats run down with it,
  # because `fail` exits the process
  run env \
    GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.294" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${temp_install_dir}" \
    bash -c "source '${_SHELL_GR_DIR}/lib/install/circleci_cli.bash'; GRI_CIRCLECI_CLI__install"
  echo "${output}"
  assert_equal 0 "${status}"
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  # The binary is not run here. Releases this old are built with a Go runtime
  # that panics on current macOS, so only check that the install produced an
  # executable under the expected name.
  assert [ -x "${temp_install_dir}/circleci" ]
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}

# From 1.0.46955 on, the archive no longer wraps its contents in a directory.
test_installation_of_release_with_flat_archive() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "circleci_cli_test__test_installation_flat")"
  echo "Temp dir created: ${temp_install_dir}"
  # `run` keeps a failed install from taking the whole bats run down with it,
  # because `fail` exits the process
  run env \
    GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="1.0.47611" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${temp_install_dir}" \
    bash -c "source '${_SHELL_GR_DIR}/lib/install/circleci_cli.bash'; GRI_CIRCLECI_CLI__install"
  echo "${output}"
  assert_equal 0 "${status}"
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  # 1.0.x prints "circleci <version> (<commit>)"
  output="$("${temp_install_dir}/circleci" version)"
  assert_output --partial "1.0.47611"
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}

# 0.1.47860 ships the legacy v0 CLI alongside the 1.0 line. Its archive is flat
# and carries the binary as "circleci-v0", which the plugin installs as "circleci"
# so that the command name stays the same across versions.
test_installation_of_v0_release() { # @test
  local temp_install_dir
  temp_install_dir="$(temp_dir "circleci_cli_test__test_installation_v0")"
  echo "Temp dir created: ${temp_install_dir}"
  # `run` keeps a failed install from taking the whole bats run down with it,
  # because `fail` exits the process
  run env \
    GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.47860" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${temp_install_dir}" \
    bash -c "source '${_SHELL_GR_DIR}/lib/install/circleci_cli.bash'; GRI_CIRCLECI_CLI__install"
  echo "${output}"
  assert_equal 0 "${status}"
  echo "Directory content:"
  ls -al "${temp_install_dir}"
  echo
  output="$("${temp_install_dir}/circleci" version)"
  assert_output --partial "0.1.47860"
  # cleanup
  rm -rf "${temp_install_dir}"
  echo "Temp dir removed"
}
