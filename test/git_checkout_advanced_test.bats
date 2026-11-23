#!/usr/bin/env bats
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /(bats-exec-(file|test)|bats-gather-tests)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
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

@test "git_checkout_advanced - dest inside another repo leaves that repo untouched" {
  # GIVEN
  local -r outer_dir="${DEST_DIR}/outer"
  local -r origin_dir="${DEST_DIR}/origin"
  for dir in "${outer_dir}" "${origin_dir}"; do
    git init -q -b main "${dir}"
    git -C "${dir}" -c user.name="test" -c user.email="test@example.com" -c commit.gpgsign=false \
      commit -q --allow-empty -m "init ${dir##*/}"
  done
  local -r outer_head="$(git -C "${outer_dir}" rev-parse HEAD)"
  # WHEN origin is checked out into a subdirectory of the outer repo
  GR_GITCO__DEPTH=-1 \
    GR_GITCO__DEPTH_FOR_SUBMODULES=-1 \
    GR_GITCO__DEST_DIR="${outer_dir}/vendor/origin" \
    GR_GITCO__ENABLED_LFS=0 \
    GR_GITCO__ENABLED_SUBMODULES=0 \
    GR_GITCO__REPO_BRANCH="main" \
    GR_GITCO__REPO_SHA1="$(git -C "${origin_dir}" rev-parse HEAD)" \
    GR_GITCO__REPO_URL="file://${origin_dir}" \
    git_checkout_advanced
  # THEN the outer repo stays on its own commit
  [ "$(git -C "${outer_dir}" rev-parse HEAD)" = "${outer_head}" ]
  #  AND the outer repo gets no remote
  [ -z "$(git -C "${outer_dir}" remote)" ]
  #  AND the subdirectory holds its own checkout of origin
  [ "$(git -C "${outer_dir}/vendor/origin" rev-parse HEAD)" = "$(git -C "${origin_dir}" rev-parse HEAD)" ]
}

@test "git_checkout_advanced - custom remote name" {
  # GIVEN a repo to clone
  local -r origin_dir="${DEST_DIR}/origin"
  local -r clone_dir="${DEST_DIR}/clone"
  git init -q -b main "${origin_dir}"
  git -C "${origin_dir}" -c user.name="test" -c user.email="test@example.com" -c commit.gpgsign=false \
    commit -q --allow-empty -m "init"
  # WHEN it is checked out with the remote named "gh"
  GR_GITCO__DEPTH=-1 \
    GR_GITCO__DEPTH_FOR_SUBMODULES=-1 \
    GR_GITCO__DEST_DIR="${clone_dir}" \
    GR_GITCO__ENABLED_LFS=0 \
    GR_GITCO__ENABLED_SUBMODULES=0 \
    GR_GITCO__REMOTE_NAME="gh" \
    GR_GITCO__REPO_BRANCH="main" \
    GR_GITCO__REPO_SHA1="$(git -C "${origin_dir}" rev-parse HEAD)" \
    GR_GITCO__REPO_URL="file://${origin_dir}" \
    git_checkout_advanced
  # THEN "gh" is the only remote
  [ "$(git -C "${clone_dir}" remote)" = "gh" ]
  #  AND the branch tracks the branch on "gh"
  [ "$(git -C "${clone_dir}" rev-parse --abbrev-ref "main@{upstream}")" = "gh/main" ]
}
