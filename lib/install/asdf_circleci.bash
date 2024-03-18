#!/usr/bin/env bash

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
else
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ ^(/bin/)?(ba)?sh$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash"        # YELLOW, NC
source "${_SHELL_GR_DIR}/lib/install/asdf.bash" # asdf_determine_install_dir, asdf_validate_install_dir, asdf_is_installed, asdf_is_version, asdf_version, _ASDF_NAME
source "${_SHELL_GR_DIR}/lib/text.bash"         # append_if_not_exists

# $1 - install_dir
ASDF_CIRCLECI_post_install() {
  if [ "${CIRCLECI:-}" = "true" ]; then
    local -r install_dir="${1}"
    asdf_validate_install_dir "${install_dir}"
    # needed for following jobs
    if [ -n "${BASH_ENV:-}" ]; then
      append_if_not_exists ". ${install_dir}/asdf.sh" "${BASH_ENV}"
    fi
    # needed when we SSH to machine for debugging
    append_if_not_exists ". ${install_dir}/asdf.sh" ~/.bashrc
  fi
}

ASDF_CIRCLECI_asdf_install() {
  local -r input_version="$1"
  local -r input_install_dir="$2"
  local -r version="${input_version}"
  local install_dir
  install_dir="$(asdf_determine_install_dir "${input_install_dir}")"
  if ! asdf_is_installed; then
    printf "${YELLOW}%s${NC}\n" "${_ASDF_NAME} is not yet installed."
    asdf_install "${version}" "${install_dir}"
    ASDF_CIRCLECI_post_install "${install_dir}"
  elif ! asdf_is_version "${version}"; then
    printf "${YELLOW}%s${NC}\n" "The installed version of ${_ASDF_NAME} ($(asdf_version)) is different then expected (${version})."
    asdf_install "${version}" "${install_dir}"
    ASDF_CIRCLECI_post_install "${install_dir}"
  else
    printf "${YELLOW}%s${NC}\n" "${_ASDF_NAME} is already installed in $(which "${_ASDF_CMD_NAME}")."
  fi
}
