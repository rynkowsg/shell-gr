#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# $1 - expected path
path_in_path() {
  local dir="$1"
  if echo "${PATH}" | tr ':' '\n' | grep -qx "${dir}"; then
    return 0 # true
  else
    return 1 # false
  fi
}

# $1 - command name
is_installed() {
  local command_name="$1"
  if command -v "${command_name}" >/dev/null; then
    return 0 # true
  else
    return 1 # false
  fi
}
