#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Function to mask the input with asterisks
mask() {
  local input="$1"
  local masked="${input//?/*}"
  echo "${masked}"
}
