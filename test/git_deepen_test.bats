#!/usr/bin/env bats
# Copyright (c) 2026 Greg Rynkowski. All rights reserved.
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
  WORK_DIR="$(temp_dir "shell-gr-git_deepen_test")"
  ORIGIN_DIR="${WORK_DIR}/origin"
  DEST_DIR="${WORK_DIR}/dest"
  git init -q -b main "${ORIGIN_DIR}"
  # The global config may sign commits and tags, which needs a key and a prompt.
  git -C "${ORIGIN_DIR}" config user.name "test"
  git -C "${ORIGIN_DIR}" config user.email "test@example.com"
  git -C "${ORIGIN_DIR}" config commit.gpgsign false
  git -C "${ORIGIN_DIR}" config tag.gpgsign false
}

teardown() {
  rm -rf "${WORK_DIR}"
}

# Adds empty commits to the origin repo.
# $1 - number of commits
add_commits() {
  local -r count="${1}"
  for ((i = 0; i < count; i++)); do
    git -C "${ORIGIN_DIR}" commit -q --allow-empty -m "commit ${i}"
  done
}

# Clones the origin repo and deepens it to the last tag.
# $1 - branch to clone
# $2 - tag to clone, optional
# $3 - clone depth, 1 by default
checkout_until_last_tag() {
  GR_GITCO__DEPTH="${3:-1}" \
    GR_GITCO__DEPTH_FOR_SUBMODULES=-1 \
    GR_GITCO__DEPTH_UNTIL_LAST_TAG=1 \
    GR_GITCO__DEST_DIR="${DEST_DIR}" \
    GR_GITCO__ENABLED_LFS=0 \
    GR_GITCO__ENABLED_SUBMODULES=0 \
    GR_GITCO__REPO_BRANCH="${1}" \
    GR_GITCO__REPO_SHA1="$(git -C "${ORIGIN_DIR}" rev-parse HEAD)" \
    GR_GITCO__REPO_TAG="${2:-}" \
    GR_GITCO__REPO_URL="file://${ORIGIN_DIR}" \
    git_checkout_advanced
}

@test "git_deepen_to_last_tag - annotated tag within the first round" {
  # GIVEN an annotated tag 3 commits behind HEAD, with history going on past
  # the first round, so the clone stays shallow
  add_commits 20
  git -C "${ORIGIN_DIR}" tag -a v1.0.0 -m "v1.0.0"
  add_commits 3
  # WHEN the branch is checked out until the last tag
  checkout_until_last_tag main
  # THEN the tag describes HEAD
  [[ "$(git -C "${DEST_DIR}" describe --tags)" == "v1.0.0-3-g"* ]]
  #  AND the history stays shallow
  [ "$(git -C "${DEST_DIR}" rev-parse --is-shallow-repository)" = "true" ]
}

@test "git_deepen_to_last_tag - lightweight tag beyond the first round" {
  # GIVEN a lightweight tag 25 commits behind HEAD
  add_commits 30
  git -C "${ORIGIN_DIR}" tag v0.1.0
  add_commits 25
  # WHEN the branch is checked out until the last tag
  checkout_until_last_tag main
  # THEN the tag describes HEAD
  [[ "$(git -C "${DEST_DIR}" describe --tags)" == "v0.1.0-25-g"* ]]
  #  AND the history stays shallow
  [ "$(git -C "${DEST_DIR}" rev-parse --is-shallow-repository)" = "true" ]
}

@test "git_deepen_to_last_tag - tag outside the history of HEAD" {
  # GIVEN a tag only on another branch
  add_commits 40
  git -C "${ORIGIN_DIR}" checkout -q -b side
  add_commits 1
  git -C "${ORIGIN_DIR}" tag v9.9.9
  git -C "${ORIGIN_DIR}" checkout -q main
  # WHEN main is checked out until the last tag
  checkout_until_last_tag main
  # THEN the full history is fetched
  [ "$(git -C "${DEST_DIR}" rev-parse --is-shallow-repository)" = "false" ]
  #  AND no tag describes HEAD
  run git -C "${DEST_DIR}" describe --tags
  [ "${status}" -ne 0 ]
}

@test "git_deepen_to_last_tag - no tags on the remote" {
  # GIVEN a repo without tags
  add_commits 40
  # WHEN the branch is checked out until the last tag
  checkout_until_last_tag main
  # THEN the full history is fetched
  [ "$(git -C "${DEST_DIR}" rev-parse --is-shallow-repository)" = "false" ]
  [ "$(git -C "${DEST_DIR}" rev-list --count HEAD)" = "40" ]
}

@test "git_deepen_to_last_tag - full clone without tags" {
  # GIVEN a repo without tags
  add_commits 5
  # WHEN the branch is cloned in full and checked out until the last tag
  run checkout_until_last_tag main "" -1
  # THEN the checkout succeeds
  [ "${status}" -eq 0 ]
  #  AND it reports that no tag is in the history
  [[ "${output}" == *"no tag in the history of HEAD"* ]]
  #  AND it neither deepens nor fetches the history again
  [[ "${output}" != *"deepening by"* ]]
  [[ "${output}" != *"fetching the full history"* ]]
}

@test "git_deepen_to_last_tag - full clone with the tags missing locally" {
  # GIVEN a full clone whose local tags were removed
  add_commits 5
  git -C "${ORIGIN_DIR}" tag v3.0.0
  add_commits 2
  checkout_until_last_tag main "" -1
  git -C "${DEST_DIR}" tag -d v3.0.0
  # WHEN the clone is deepened to the last tag
  (cd "${DEST_DIR}" && git_deepen_to_last_tag)
  # THEN the tag is fetched and describes HEAD
  [[ "$(git -C "${DEST_DIR}" describe --tags)" == "v3.0.0-2-g"* ]]
  #  AND the history stays full
  [ "$(git -C "${DEST_DIR}" rev-parse --is-shallow-repository)" = "false" ]
}

@test "git_deepen_to_last_tag - branch without an upstream" {
  # GIVEN a shallow clone whose branch tracks nothing
  add_commits 5
  git -C "${ORIGIN_DIR}" tag v4.0.0
  add_commits 3
  checkout_until_last_tag main
  git -C "${DEST_DIR}" tag -d v4.0.0
  git -C "${DEST_DIR}" branch --unset-upstream
  # WHEN the clone is deepened to the last tag
  run bash -c "cd '${DEST_DIR}' && source '${_SHELL_GR_DIR}/lib/git_deepen.bash' && git_deepen_to_last_tag"
  # THEN it fails
  [ "${status}" -eq 1 ]
  #  AND it says why
  [[ "${output}" == *"neither given nor found in the upstream of HEAD"* ]]
}

@test "git_deepen_to_last_tag - remote and refspec given without an upstream" {
  # GIVEN a shallow clone whose branch tracks nothing
  add_commits 5
  git -C "${ORIGIN_DIR}" tag v5.0.0
  add_commits 3
  checkout_until_last_tag main
  git -C "${DEST_DIR}" tag -d v5.0.0
  git -C "${DEST_DIR}" branch --unset-upstream
  # WHEN the clone is deepened with the remote and the refspec given
  (
    cd "${DEST_DIR}" \
      && GR_GITDEEPEN__REMOTE="origin" \
        GR_GITDEEPEN__REFSPEC="refs/heads/main:refs/remotes/origin/main" \
        git_deepen_to_last_tag
  )
  # THEN the tag is fetched and describes HEAD
  [[ "$(git -C "${DEST_DIR}" describe --tags)" == "v5.0.0-3-g"* ]]
}

@test "git_deepen_to_last_tag - checkout by tag" {
  # GIVEN a tag on HEAD
  add_commits 20
  git -C "${ORIGIN_DIR}" tag v2.0.0
  # WHEN the tag is checked out until the last tag
  checkout_until_last_tag main v2.0.0
  # THEN the tag describes HEAD exactly
  [ "$(git -C "${DEST_DIR}" describe --tags --exact-match)" = "v2.0.0" ]
  #  AND nothing beyond HEAD is fetched
  [ "$(git -C "${DEST_DIR}" rev-list --count HEAD)" = "1" ]
}
