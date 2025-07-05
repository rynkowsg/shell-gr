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
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/error.bash" # fail_code

find_checksum_program() {
  local -r algo="${GR_CHECKSUM__ALGO:-}"
  local -r algoLower="${algo,,}"
  # prefer openssl if available
  command -v "openssl" >/dev/null && {
    printf '%s\n' "openssl"
    return
  }
  # 1. SHA-family → SHA helpers
  if [[ "${algoLower}" == sha* ]]; then
    local clean=${algoLower#sha} # “sha256” → “256”
    for cmd in "gsha${clean}sum" "sha${clean}sum" "shasum"; do
      command -v "${cmd}" >/dev/null && {
        printf '%s\n' "${cmd}"
        return
      }
    done
  # 2. MD5 → md5 helpers only
  elif [[ "${algoLower}" == md5 ]]; then
    for cmd in "md5sum" "md5"; do
      command -v "${cmd}" >/dev/null && {
        printf '%s\n' "${cmd}"
        return
      }
    done
  else
    printf '%s\n' ""
    return
  fi
}

verify_with_openssl() {
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum="${GR_CHECKSUM__CHECKSUM:-}"
  local -r algo="${GR_CHECKSUM__ALGO:-}"
  # ── 1. Input validation ──────────────────────────────────────────────
  [ -n "${file_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__FILE_PATH"
  [ -n "${checksum}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__CHECKSUM"
  [ -n "${algo}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__ALGO"
  [ -f "${file_path}" ] || fail_code 3 "File not found: ${file_path}"
  command -v openssl >/dev/null || fail_code 4 "openssl command not found"
  # ── 2. Compute checksum ──────────────────────────────────────────────
  local -r algoLower="${algo,,}" # e.g. SHA256 → sha256
  local actual
  actual="$(openssl dgst "-${algoLower}" "${file_path}" | awk '{print $NF}')" || return 5
  # ── 3. Compare against expected value ────────────────────────────────
  local actualLower checksumLower
  actualLower="$(echo "${actual}" | tr 'A-F' 'a-f')"
  checksumLower="$(echo "${checksum}" | tr 'A-F' 'a-f')"
  if [[ "${actualLower}" == "${checksumLower}" ]]; then
    return 0 # checksum matches
  else
    echo "Checksum mismatch" >&2
    echo "Expected: ${checksumLower}" >&2
    echo "Actual:   ${actualLower}" >&2
    return 1
  fi
}

verify_with_shasum() {
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum="${GR_CHECKSUM__CHECKSUM:-}"
  local -r algo="${GR_CHECKSUM__ALGO:-}"
  local -r shaAlgoSumCmdFormat="${GR_CHECKSUM__SHA_CMD_FMT:-"sha%ssum"}"
  # ── 1. Input validation ──────────────────────────────────────────────
  [ -n "${file_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__FILE_PATH"
  [ -n "${checksum}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__CHECKSUM"
  [ -n "${algo}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__ALGO"
  [ -f "${file_path}" ] || fail_code 3 "File not found: ${file_path}"
  # ── 2. Compute checksum ──────────────────────────────────────────────
  local -r algoLower="${algo,,}"        # e.g. SHA256 → sha256
  local -r algoClean="${algoLower#sha}" # “sha256” → “256”
  # shellcheck disable=SC2059
  local -r shaAlgoSumCmd="$(printf "${shaAlgoSumCmdFormat}" "${algoClean}")"
  read -ra shaAlgoSumCmdArgs <<<"${shaAlgoSumCmd}"
  local actual
  actual="$("${shaAlgoSumCmdArgs[@]}" "${file_path}" | awk '{print $1}')" || return 5
  # ── 3. Compare against expected value ────────────────────────────────
  local actualLower checksumLower
  actualLower="$(echo "${actual}" | tr 'A-F' 'a-f')"
  checksumLower="$(echo "${checksum}" | tr 'A-F' 'a-f')"
  if [[ "${actualLower}" == "${checksumLower}" ]]; then
    return 0 # checksum matches
  else
    echo "Checksum mismatch" >&2
    echo "Expected: ${checksumLower}" >&2
    echo "Actual:   ${actualLower}" >&2
    return 1
  fi
}

verify_with_md5sum() {
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum="${GR_CHECKSUM__CHECKSUM:-}"
  # ── 1. Input validation ──────────────────────────────────────────────
  [ -n "${file_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__FILE_PATH"
  [ -n "${checksum}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__CHECKSUM"
  [ -f "${file_path}" ] || fail_code 3 "File not found: ${file_path}"
  # ── 2. Compute checksum ──────────────────────────────────────────────
  local -r md5sumCmd="md5sum"
  actual="$("${md5sumCmd}" "${file_path}" | awk '{print $1}')" || return 5
  # ── 3. Compare against expected value ────────────────────────────────
  local actualLower checksumLower
  actualLower="$(echo "${actual}" | tr 'A-F' 'a-f')"
  checksumLower="$(echo "${checksum}" | tr 'A-F' 'a-f')"
  if [[ "${actualLower}" == "${checksumLower}" ]]; then
    return 0 # checksum matches
  else
    echo "Checksum mismatch" >&2
    echo "Expected: ${checksumLower}" >&2
    echo "Actual:   ${actualLower}" >&2
    return 1
  fi
}

verify_with_md5() {
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum="${GR_CHECKSUM__CHECKSUM:-}"
  # ── 1. Input validation ──────────────────────────────────────────────
  [ -n "${file_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__FILE_PATH"
  [ -n "${checksum}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__CHECKSUM"
  [ -f "${file_path}" ] || fail_code 3 "File not found: ${file_path}"
  # ── 2. Compute checksum ──────────────────────────────────────────────
  local -r md5Cmd="md5"
  local actual
  actual="$("${md5Cmd}" "${file_path}" | awk '{print $NF}')" || return 5
  # ── 3. Compare against expected value ────────────────────────────────
  local actualLower checksumLower
  actualLower="$(echo "${actual}" | tr 'A-F' 'a-f')"
  checksumLower="$(echo "${checksum}" | tr 'A-F' 'a-f')"
  if [[ "${actualLower}" == "${checksumLower}" ]]; then
    return 0 # checksum matches
  else
    echo "Checksum mismatch" >&2
    echo "Expected: ${checksumLower}" >&2
    echo "Actual:   ${actualLower}" >&2
    return 1
  fi
}

verify_with_checksum_string() {
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum="${GR_CHECKSUM__CHECKSUM:-}"
  local -r algo="${GR_CHECKSUM__ALGO:-}"
  # ── 1. Input validation ──────────────────────────────────────────────
  [ -n "${file_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__FILE_PATH"
  [ -n "${checksum}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__CHECKSUM"
  [ -n "${algo}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__ALGO"
  [ -f "${file_path}" ] || fail_code 3 "File not found: ${file_path}"
  [[ " md5 sha1 sha224 sha256 sha384 sha512 " == *" ${algo} "* ]] || fail_code 4 "Not supported algo: ${algo}"
  # ── 2. Locate a checksum helper program ──────────────────────────────
  local -r algoLower="${algo,,}"
  local program
  program=$(find_checksum_program "${algoLower}")
  [ -n "${program}" ] || fail_code 4 "No suitable checksum program found for algorithm: ${algoLower}"
  # ── 3. Delegate to the correct validator ─────────────────────────────
  #     Each validator is expected to return 0 on success, 1 on mismatch.
  case "${program}" in
    openssl)
      GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" GR_CHECKSUM__ALGO="${algoLower}" \
        verify_with_openssl || return 1
      ;;
    shasum)
      GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" GR_CHECKSUM__ALGO="${algoLower}" \
        GR_CHECKSUM__SHA_CMD_FMT="shasum -a %s" verify_with_shasum || return 1
      ;;
    gsha*sum)
      GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" GR_CHECKSUM__ALGO="${algoLower}" \
        GR_CHECKSUM__SHA_CMD_FMT="gsha%ssum" verify_with_shasum || return 1
      ;;
    sha*sum)
      GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" GR_CHECKSUM__ALGO="${algoLower}" \
        GR_CHECKSUM__SHA_CMD_FMT="sha%ssum" verify_with_shasum || return 1
      ;;
    md5sum)
      GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" verify_with_md5sum || return 1
      ;;
    md5)
      GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" verify_with_md5 || return 1
      ;;
    *)
      # Fallback if we encounter an unexpected helper
      fail_code 5 "Unknown checksum program returned: ${program}"
      ;;
  esac
}

#
#  Function: verify_with_checksum_string_in_file

#  Description: Verifies the integrity of a file by comparing its checksum with a provided checksum string in a file.

#  Sample usage:
#    GR_CHECKSUM__ALGO=sha256 \
#      GR_CHECKSUM__FILE_PATH=resources/sample.txt \
#      GR_CHECKSUM__CHECKSUM_PATH=resources/sample.txt.sha256 \
#      verify_with_checksum_string_in_file
#
verify_with_checksum_string_in_file() {
  # inputs
  local -r file_path="${GR_CHECKSUM__FILE_PATH:-}"
  local -r checksum_path="${GR_CHECKSUM__CHECKSUM_PATH:-}"
  local -r algo="${GR_CHECKSUM__ALGO:-}"
  # inputs validation
  [ -n "${file_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__FILE_PATH"
  [ -n "${checksum_path}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__CHECKSUM_PATH"
  [ -n "${algo}" ] || fail_code 2 "Missing required environment variable: GR_CHECKSUM__ALGO"
  [ -f "${file_path}" ] || fail_code 3 "File not found: ${file_path}"
  [ -f "${checksum_path}" ] || fail_code 3 "File not found: ${file_path}"
  # delegate
  local -r checksum="$(cat "${checksum_path}")"
  GR_CHECKSUM__FILE_PATH="${file_path}" GR_CHECKSUM__CHECKSUM="${checksum}" GR_CHECKSUM__ALGO="${algo}" \
    verify_with_checksum_string
}
