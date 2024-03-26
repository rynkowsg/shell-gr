#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# Applies format for collection of files
#
# Example:
#
#  - check:
#
#    find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
#          | format check bash
#
#  - apply:
#
#    find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
#          | format apply bash
#
#  - with patches, example for check:
#
#    find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
#          | WITH_PATCHES=1 format check bash
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
else
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/error.bash"     # run_with_unset_e
source "${_SHELL_GR_DIR}/lib/log_utils.bash" # print_section_title
source "${_SHELL_GR_DIR}/lib/trap.bash"      # add_on_exit

DEBUG=${DEBUG:-0}
WITH_PATCHES=${WITH_PATCHES:-0}
PATCH_PRE_PATH=${PATCH_PRE_PATH:-"@bin/res/pre-format.patch"}
PATCH_POST_PATH=${PATCH_POST_PATH:-"@bin/res/post-format.patch"}

if [ "${DEBUG}" = 1 ]; then
  echo "WITH_PATCHES: ${WITH_PATCHES}"
  echo "\$@: " "$@"
fi

GR_FORMAT_validate_op() {
  local op="${1}"
  if [ "${op}" == "check" ] || [ "${op}" == "apply" ]; then
    :
  else
    echo "'${op}' is not valid operation. Only available are: 'check' & 'apply'."
    exit 1
  fi
}

# $1 - operation type, enum: check, apply
# $2 - shell type, e.g. bash, bats
format() {
  local op="$1"
  local shell_type="${2:-bash}"
  GR_FORMAT_validate_op "${op}"
  print_section_title "Format '${shell_type}' files (${op})"
  # DEFINE ERROR_CODES
  declare -A error_codes
  # workaround to fix unbound error
  error_codes["key1"]="value1"
  unset 'error_codes["key1"]'
  # apply shfmt - process
  shfmt_params=()
  shfmt_params+=(--indent 2)
  shfmt_params+=(--case-indent)
  shfmt_params+=(--binary-next-line)
  if [[ "${op}" == "check" ]]; then
    shfmt_params+=(--diff)
  elif [[ "${op}" == "apply" ]]; then
    shfmt_params+=(--write)
  fi
  # PROCESS
  while IFS= read -r file; do
    echo "- processing $file"
    run_with_unset_e shfmt --language-dialect "${shell_type}" "${shfmt_params[@]}" "${file}"
    local res=$?
    if [ ${res} -ne 0 ]; then
      error_codes["${file}"]=$res
    fi
  done
  # REPORT ERRORS
  local errors_count=${#error_codes[@]}
  if [ "${errors_count}" -ne 0 ]; then
    # Print error codes before exiting
    printf "\n%s\n" "Error codes per file:"
    for file in "${!error_codes[@]}"; do
      echo "$file: ${error_codes[$file]}"
    done
    printf "%s\n" ""
    return "${errors_count}"
  fi
  printf "%s\n" ""
}

apply_pre_patch() {
  [ -f "${PATCH_PRE_PATH}" ] && git apply --allow-empty "${PATCH_PRE_PATH}"
  res=$?
  if [ $res -ne 0 ]; then
    echo "Failed to apply pre-format.patch"
    exit $res
  fi
}

apply_post_patch() {
  [ -f "${PATCH_POST_PATH}" ] && git apply --allow-empty "${PATCH_POST_PATH}"
  res=$?
  if [ $res -ne 0 ]; then
    echo "Failed to apply post-format.patch"
    exit $res
  fi
}

# shfmt has this limitation that doesn't allow to disable formatting for certain lines.
# By applying patches before shfmt and after, one could overcome this limitation.
format_with_patches() {
  # inputs
  local op="${1}"
  local shell_type="${2}"
  GR_FORMAT_validate_op "${op}"
  apply_pre_patch
  add_on_exit apply_post_patch
  # FORMAT
  format "$@"
}

# format but behaviour based on env variables
format_with_env() {
  if [ "${WITH_PATCHES}" = 1 ]; then
    format_with_patches "$@"
  else
    format "$@"
  fi
}

main() {
  format_with_env "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
