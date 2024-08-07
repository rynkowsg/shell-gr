#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

HOME="${HOME:-"$(eval echo ~)"}"

# $1 - path
normalized_path() {
  local path=$1
  # expand tilde (~) with eval
  eval path="${path}"
  # save prefix that otherwise we would loose in the next step
  local prefix=
  if [[ "${path}" == /* ]]; then
    prefix="/"
  elif [[ "${path}" == ./* ]]; then
    prefix="./"
  fi
  # remove all redundant /, . and ..
  local old_IFS=$IFS
  IFS='/'
  local -a path_array
  for segment in ${path}; do
    case ${segment} in
      "" | ".")
        :
        ;;
      "..")
        # Remove the last segment for parent directory
        [ ${#path_array[@]} -gt 0 ] && unset 'path_array[-1]'
        ;;
      *)
        path_array+=("${segment}")
        ;;
    esac
  done
  # compose path
  read -r joined < <(echo "${path_array[*]}")
  local -r result="${prefix}${joined}"
  IFS=${old_IFS}
  echo "${result}"
}

# $1 - path
absolute_path() {
  local path="${1}"
  local normalized
  normalized="$(normalized_path "${path}")"
  cd "${normalized}" || exit 1
  pwd -P
}
