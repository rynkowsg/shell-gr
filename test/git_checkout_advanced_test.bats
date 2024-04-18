#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/git_checkout_advanced.bash"
source "${_SHELL_GR_DIR}/lib/temp.bash"

setup() {
  DEST_DIR="$(temp_dir "shell-gr-git_checkout_advanced_test")"
}

teardown() {
  rm -rf "${DEST_DIR}"
}

@test "git_checkout_advanced - shallow checkout with submodules behind HEAD" {
  GR_GITCO__DEBUG=false \
    GR_GITCO__DEBUG_GIT=false \
    GR_GITCO__DEPTH=1 \
    GR_GITCO__DEPTH_FOR_SUBMODULES=1 \
    GR_GITCO__DEST_DIR="${DEST_DIR}" \
    GR_GITCO__ENABLED_LFS=0 \
    GR_GITCO__ENABLED_SUBMODULES=1 \
    GR_GITCO__REPO_BRANCH="master-latest-with-l2-init-commit" \
    GR_GITCO__REPO_SHA1="6ff1d1a" \
    GR_GITCO__REPO_URL="https://github.com/rynkowsg/test-clone-repo-l1.git" \
    git_checkout_advanced
  ls -al "${DEST_DIR}"
}
