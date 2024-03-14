#!/usr/bin/env bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# Applies shellcheck for collection of files
#
# Example:
#
#    find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
#          | lint bash
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Path Initialization
_GR_TOOL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
_GR_TOOL_ROOT_DIR="$(cd "${_GR_TOOL_SCRIPT_DIR}/../.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${SHELL_GR_DIR:-"${_GR_TOOL_ROOT_DIR}"}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/error.bash"     # run_with_unset_e
source "${_SHELL_GR_DIR}/lib/log_utils.bash" # print_section_title

# $1 - shell type, e.g. bash, bats
lint() {
  local shell_type="${1}"
  print_section_title "Lint '${shell_type}' files"
  # DEFINE ERROR_CODES
  declare -A error_codes
  # workaround to fix unbound error
  error_codes["key1"]="value1"
  unset 'error_codes["key1"]'
  # PROCESS
  while IFS= read -r file; do
    echo "- processing $file"
    run_with_unset_e shellcheck --shell="${shell_type}" --external-sources "${file}"
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  lint "$@"
fi
