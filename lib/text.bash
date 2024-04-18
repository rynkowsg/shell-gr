#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

append_if_not_exists() {
  local -r line="$1"
  local -r file="$2"
  # if file does not exist or line does not exist in file
  if [ ! -f "${file}" ] || ! grep -qxF -- "${line}" "${file}"; then
    echo "${line}" >>"${file}"
  fi
}
