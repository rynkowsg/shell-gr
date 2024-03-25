#!/usr/bin/env bats

# Path Initialization
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${TEST_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/git_checkout_advanced.bash"
source "${ROOT_DIR}/lib/temp.bash"

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
