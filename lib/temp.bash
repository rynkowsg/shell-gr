#!/usr/bin/env bash

temp_file() {
  local -r prefix="${1}"
  mktemp -t "${prefix}-$(date +%Y%m%d_%H%M%S)-XXXXX"
}

temp_dir() {
  local -r prefix="${1}"
  mktemp -d -t "${prefix}-$(date +%Y%m%d_%H%M%S)-XXXXX"
}
