#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

temp_file() {
  local -r prefix="${1}"
  mktemp -t "${prefix}-$(date +%Y%m%d_%H%M%S)-XXXXX"
}

temp_dir() {
  local -r prefix="${1}"
  mktemp -d -t "${prefix}-$(date +%Y%m%d_%H%M%S)-XXXXX"
}
