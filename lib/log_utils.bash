#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

print_dash_line_as_long_as() {
  local input_string="$1"
  local string_length="${#input_string}"
  printf '%*s\n' "$string_length" '' | tr ' ' '-'
}

print_section_title() {
  local msg="$1"
  print_dash_line_as_long_as "${msg}"
  printf "%s\n" "${msg}"
  print_dash_line_as_long_as "${msg}"
  printf "%s\n" ""
}
