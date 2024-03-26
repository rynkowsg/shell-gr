#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/../.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash" # YELLOW, NC
source "${_SHELL_GR_DIR}/lib/error.bash" # assert_not_empty

# shellcheck disable=SC2034
GH_REPO="https://github.com/clj-kondo/clj-kondo"
TOOL_NAME="clj-kondo"
TOOL_TEST="clj-kondo --help"

CURL_OPTS=(-fsSL)
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  CURL_OPTS=("${CURL_OPTS[@]}" -H "Authorization: token ${GITHUB_API_TOKEN}")
fi

fail() {
  echo -e "asdf-${TOOL_NAME}: $*"
  exit 1
}
