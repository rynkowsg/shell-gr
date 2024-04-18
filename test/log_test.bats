#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/bats_assert.bash" # assert_equal
source "${_SHELL_GR_DIR}/lib/color.bash"
source "${_SHELL_GR_DIR}/lib/log.bash"

log_error_f__color_off() { # @test
  res=$(COLOR=0 log_error_f "%s, %s\n" "test" "test 2")
  assert_equal "${res}" "test, test 2"
}

log_error_f__color_on() { # @test
  res=$(COLOR=1 log_error_f "%s, %s\n" "test" "test 2")
  [ "${res}" == "$(printf "${RED}%s\n${NC}" "test, test 2")" ]
}

log_error__color_off() { # @test
  res=$(COLOR=0 log_error "test")
  [ "${res}" == "test" ]
}

log_error__color_on() { # @test
  res=$(COLOR=1 log_error "test")
  # shellcheck disable=SC2059
  [ "${res}" == "$(printf "${RED}test\n${NC}")" ]
}

log_warning__color_off() { # @test
  res=$(COLOR=0 log_warning "test")
  [ "${res}" == "test" ]
}

log_warning__color_on() { # @test
  res=$(COLOR=1 log_warning "test")
  # shellcheck disable=SC2059
  [ "${res}" == "$(printf "${YELLOW}test\n${NC}")" ]
}

log_debug__debug_on() { # @test
  res=$(DEBUG=1 log_debug "test")
  [ "${res}" == "test" ]
}

log_debug__debug_off() { # @test
  res=$(DEBUG=0 log_debug "test")
  [ "${res}" == "" ]
}
