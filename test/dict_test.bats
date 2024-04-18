#!/usr/bin/env bats
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
_SCRIPT_PATH=$([[ $0 =~ /bats-exec-(file|test)$ ]] && echo "${BATS_TEST_FILENAME}" || echo "${BASH_SOURCE[0]:-$0}")
_TEST_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
_ROOT_DIR="$(cd "${_TEST_DIR}/.." && pwd -P || exit 1)"
_SHELL_GR_DIR="${_ROOT_DIR}"
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/dict.bash"

@test "dict_equal - same" {
  declare -A mydict=(
    [key1]="value1"
    [key2]="value2"
    [key3]="value3"
  )
  declare -A mydict2=(
    [key1]="value1"
    [key2]="value2"
    [key3]="value3"
  )
  dict_equal mydict mydict2
}

@test "dict_equal - different length" {
  bats_require_minimum_version 1.5.0
  declare -A mydict1=(
    [key1]="value1"
    [key2]="value2"
    [key3]="value3"
  )
  declare -A mydict2=(
    [key1]="value1"
    [key2]="value2"
  )
  run ! dict_equal mydict1 mydict2
}

@test "dict_equal - different content" {
  bats_require_minimum_version 1.5.0
  # shellcheck disable=SC2034
  declare -A mydict1=(
    [key1]="value1"
    [key2]="value2"
    [key3]="value3"
  )
  # shellcheck disable=SC2034
  declare -A mydict2=(
    [key1]="value1"
    [key2]="value2"
    [key3]="value3-"
  )
  run ! dict_equal mydict1 mydict2
}

@test "normalized_path - remove" {
  # shellcheck disable=SC2034
  declare -A mydict=(
    [key1]="value1"
    [key2]="value2"
    [key3]="value3"
  )
  # serialize
  # shellcheck disable=SC2034
  declare serialized_dict
  serialize_dict mydict serialized_dict
  # deserialize
  # shellcheck disable=SC2034
  declare -A mydict_restored
  deserialize_to_dict serialized_dict mydict_restored
  # verify
  dict_equal mydict mydict_restored
}
