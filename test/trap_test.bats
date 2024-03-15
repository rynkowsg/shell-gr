#!/usr/bin/env bats

# Path Initialization
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${TEST_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
source "${ROOT_DIR}/lib/trap.bash"

@test "add_on_exit - two trap actions are executed" {
  export ROOT_DIR
  output=$(bash -c "$(
    cat <<-'EOF'
source "${ROOT_DIR}/lib/trap.bash"
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
