#!/usr/bin/env bash
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# Echo a PATH-like string with DIR prepended, unless DIR is already present.
# Usage: export PATH="$(path_prepend "${PATH}" "${HOME}/.local/bin")"
path_prepend() {
  local current="${1}"
  local dir="${2}"
  case ":${current}:" in
    *":${dir}:"*) printf '%s' "${current}" ;;
    *) printf '%s' "${dir}:${current}" ;;
  esac
}
