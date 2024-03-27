#!/usr/bin/env bats
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/trap.bash"

@test "add_on_exit - two trap actions are executed" {
  export _ROOT_DIR
  output=$(bash -c "$(
    cat <<-'EOF'
source "${_ROOT_DIR}/lib/trap.bash"
echo "Script started"
echo "File 1 created"
add_on_exit "echo \"File 1 removed\""
echo "File 2 created"
add_on_exit "echo \"File 2 removed\""
echo "Script end"
EOF
  )")
  expected=$(
    cat <<EOF
Script started
File 1 created
File 2 created
Script end
File 1 removed
File 2 removed
EOF
  )
  [ "${output}" == "${expected}" ]
}
