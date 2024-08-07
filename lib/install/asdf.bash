#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/../.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/install_common.bash" # is_installed

_ASDF_NAME="asdf"
_ASDF_CMD_NAME="${_ASDF_NAME}"

_ASDF_REPO="${ASDF_REPO:-"https://github.com/asdf-vm/asdf.git"}"
_ASDF_VERSION_REGEX="[0-9]+\.[0-9]+\.[0-9]+"

# $1 - version
asdf_validate_version() {
  local version="$1"
  local version_regex="^${_ASDF_VERSION_REGEX}$"
  if [[ $version =~ $version_regex ]]; then
    : # version matches regex
  elif [ -z "${version}" ]; then
    : # version is empty
  else
    printf "${RED}%s${NC}\n" "The version ${version} is invalid."
    exit 1
  fi
}

# $1 - install dir
asdf_validate_install_dir() {
  local install_dir="${1}"
  if [ -d "${install_dir}" ]; then
    :
    # todo: check whether is empty
  else
    if [ -z "${install_dir}" ]; then
      printf "${RED}%s${NC}\n" "The install_dir can't be empty."
      exit 1
    fi
  fi
}

asdf_version() {
  asdf --version | sed "s|v\(${_ASDF_VERSION_REGEX}\)-.*|\1|"
}

# $1 - expected version
asdf_is_version() {
  local expected_ver="$1"
  if [ "$(asdf_version)" = "${expected_ver}" ]; then
    return 0 # true
  else
    return 1 # false
  fi
}

asdf_is_installed() {
  is_installed "${_ASDF_CMD_NAME}"
}

# $1 - install dir
asdf_determine_install_dir() {
  local install_dir_default="${HOME}/.asdf"
  local install_dir="${1:-"${install_dir_default}"}"
  echo "${install_dir}"
}

# $1 - version
# $2 - install_dir
asdf_install() {
  local version="${1}"
  local install_dir_default="${HOME}/.asdf"
  local install_dir="${2}"
  asdf_validate_version "${version}"
  asdf_validate_install_dir "${install_dir}"
  mkdir -p "${install_dir}"
  local install_dir_absolute
  install_dir_absolute="$(absolute_path "${install_dir}")"
  # Installation by cloning repo. More:
  # https://asdf-vm.com/guide/getting-started.html#_3-install-asdf
  local git_params=()
  git_params+=(-C "${HOME}")
  git_params+=(-c advice.detachedHead=false)
  local git_clone_params=()
  if [ -n "${version}" ]; then
    git_clone_params+=(--branch "v${version}")
  fi
  git_clone_params+=(--depth 1)
  git "${git_params[@]}" clone "${git_clone_params[@]}" "${_ASDF_REPO}" "${install_dir_absolute}"
}
