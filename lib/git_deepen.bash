#!/usr/bin/env bash
# Copyright (c) 2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash" # GREEN, NC, RED, YELLOW

# Deepens a shallow repo until the history of HEAD reaches a tag, then fetches
# the tags found in that history, so `git describe --tags` works.
# Each round deepens twice as much as the one before. When no tag shows up
# within these rounds, or the remote has no tags, it fetches the full history.
# A repo with the full history is not deepened, but it still gets the tags in
# that history when they were not fetched.
# Works in the current directory.
# Inputs:
# GR_GITDEEPEN__REMOTE  - remote name, e.g. origin
# GR_GITDEEPEN__REFSPEC - refspec to deepen, e.g. refs/heads/main:refs/remotes/origin/main
# Each input left empty is taken from the upstream of the current branch. When
# it is neither given nor found there, the function fails.
git_deepen_to_last_tag() {
  local remote="${GR_GITDEEPEN__REMOTE:-}"
  local refspec="${GR_GITDEEPEN__REFSPEC:-}"
  local -r max_rounds=6

  printf "${GREEN}%s${NC}\n" "Deepening to the last tag..."
  if git describe --tags --abbrev=0 HEAD >/dev/null 2>&1; then
    printf "%s\n" "- tag already in history: $(git describe --tags --abbrev=0 HEAD)"
    printf "%s\n" ""
    return 0
  fi

  if [ -z "${remote}" ] || [ -z "${refspec}" ]; then
    # Without a ref, for-each-ref would list every ref, so a detached HEAD
    # is checked first.
    local head_ref upstream=""
    head_ref="$(git symbolic-ref -q HEAD || true)"
    if [ -n "${head_ref}" ]; then
      upstream="$(git for-each-ref --format="%(upstream:remotename) %(upstream:remoteref) %(upstream)" "${head_ref}")"
    fi
    local upstream_remote upstream_remote_ref upstream_tracking_ref
    read -r upstream_remote upstream_remote_ref upstream_tracking_ref <<<"${upstream}"
    if [ -z "${remote}" ]; then
      remote="${upstream_remote}"
    fi
    # The refspec names only the branch of HEAD, since a bare
    # `git fetch <remote>` takes every branch the remote has.
    if [ -z "${refspec}" ] && [ -n "${upstream_remote_ref}" ]; then
      refspec="${upstream_remote_ref}:${upstream_tracking_ref}"
    fi
  fi
  if [ -z "${remote}" ] || [ -z "${refspec}" ]; then
    printf "${RED}%s${NC}\n" "Can not deepen: the remote or the refspec is neither given nor found in the upstream of HEAD."
    return 1
  fi
  readonly remote refspec
  printf "%s\n" "- remote: ${remote}"
  printf "%s\n" "- refspec: ${refspec}"

  # Map each remote tag to the commit it points to. An annotated tag is listed
  # twice, and its line ending with "^{}" holds the commit, so that line wins.
  local -A tag_commits=()
  local sha ref name
  while read -r sha ref; do
    name="${ref#refs/tags/}"
    if [[ "${name}" == *"^{}" ]]; then
      tag_commits["${name%"^{}"}"]="${sha}"
    elif [ -z "${tag_commits["${name}"]:-}" ]; then
      tag_commits["${name}"]="${sha}"
    fi
  done < <(git ls-remote --tags "${remote}")
  # Turn it around to look up tags by commit. Ref names cannot hold spaces, so
  # the names of tags on one commit are kept in one space separated string.
  local -A commit_tags=()
  for name in "${!tag_commits[@]}"; do
    commit_tags["${tag_commits["${name}"]}"]+="${name} "
  done

  local step=10
  local round=0
  local -a found_refspecs names
  while true; do
    found_refspecs=()
    if [ ${#commit_tags[@]} -gt 0 ]; then
      # grep streams the history, so even a long one is never held in memory.
      while read -r sha; do
        read -r -a names <<<"${commit_tags["${sha}"]}"
        for name in "${names[@]}"; do
          found_refspecs+=("refs/tags/${name}:refs/tags/${name}")
        done
      done < <(git rev-list HEAD | grep -F -x -f <(printf "%s\n" "${!commit_tags[@]}"))
    fi
    if [ ${#found_refspecs[@]} -gt 0 ]; then
      git fetch --no-tags "${remote}" "${found_refspecs[@]}"
      printf "%s\n" "- found tag: $(git describe --tags --abbrev=0 HEAD)"
      printf "%s\n" ""
      return 0
    fi
    if [ "$(git rev-parse --is-shallow-repository)" != "true" ]; then
      printf "${YELLOW}%s${NC}\n" "- no tag in the history of HEAD"
      printf "%s\n" ""
      return 0
    fi
    round=$((round + 1))
    if [ ${#commit_tags[@]} -eq 0 ] || [ "${round}" -gt "${max_rounds}" ]; then
      printf "%s\n" "- fetching the full history"
      git fetch --no-tags --unshallow "${remote}" "${refspec}"
    else
      printf "%s\n" "- deepening by ${step} commits"
      git fetch --no-tags --deepen "${step}" "${remote}" "${refspec}"
      step=$((step * 2))
    fi
  done
}
