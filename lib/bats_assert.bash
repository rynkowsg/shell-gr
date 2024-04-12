#!/usr/bin/env bash
# Copyright (c) 2024. All rights reserved.
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
source "${_SHELL_GR_DIR}/.github_deps/ztombol/bats-assert@v0.3.0/src/assert.bash"
source "${_SHELL_GR_DIR}/.github_deps/ztombol/bats-support@v0.3.0/src/error.bash"
source "${_SHELL_GR_DIR}/.github_deps/ztombol/bats-support@v0.3.0/src/lang.bash"
source "${_SHELL_GR_DIR}/.github_deps/ztombol/bats-support@v0.3.0/src/output.bash"
