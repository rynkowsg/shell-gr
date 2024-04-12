#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Debug disabled by default
DEBUG=${DEBUG:-0}

is_debug() {
  case "${DEBUG}" in
    1 | "true") return 0 ;; # true
    *) return 1 ;;          # false
  esac
}
