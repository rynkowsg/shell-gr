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
source "${_SHELL_GR_DIR}/lib/log.bash" # log_info

verify_with_checksum_string_in_file() {
  # inputs
  local -r algo="${GR_CHECKSUM__ALGO:-}"
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum_path="${GR_CHECKSUM__CHECKSUM_PATH:-}"
  # inputs validation
  [ -z "${algo}" ] && fail "checksum algorithm can't be empty"
  [ -z "${file_path}" ] && fail "file path can't be empty"
  [ -z "${checksum_path}" ] && fail "checksum path can't be empty"

  local -r cmd="${algo}sum"
  if ! command -v "${cmd}" >/dev/null; then
    log_info "Check verification skipped due to missing '${cmd}'."
  else
    if echo "$(cat "${checksum_path}") ${file_path}" | "${cmd}" --check >/dev/null 2>&1; then
      log_info "Checksum verification successful: The file is intact."
    else
      log_info "Checksum verification failed: The file's integrity is compromised. Try do download file again."
      fail "Installation terminated due to integrity check failure."
    fi
  fi
}
