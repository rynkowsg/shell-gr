#!/usr/bin/env bash

append_if_not_exists() {
  local -r line="$1"
  local -r file="$2"
  if ! grep -qxF -- "${line}" "${file}"; then
    echo "${line}" >>"${file}"
  fi
}
