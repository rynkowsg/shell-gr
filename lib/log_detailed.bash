#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

#
# Allows to create log functions with information about file and date
#
# Usage:
#
#     # define
#     FILENAME="$(basename "${SCRIPT_PATH}")"
#     log_info() { printf "$(log_template_info "${FILENAME}")\n" "$1"; }
#     log_error() { printf "$(log_template_error "${FILENAME}")\n" "$1"; }
#
#     # use
#     log_info "action done"
#

GR__LOG_ENHANCED__HOSTNAME="$(hostname)"

log_template_error() {
  local -r filename="$1"
  printf "%s %s %s [%s] %s" "$(date -u +"%FT%T.%3NZ")" "${GR__LOG_ENHANCED__HOSTNAME}" "ERROR" "${filename}" "%s"
}

log_template_warning() {
  local -r filename="$1"
  printf "%s %s %s [%s] %s" "$(date -u +"%FT%T.%3NZ")" "${GR__LOG_ENHANCED__HOSTNAME}" "WARNING" "${filename}" "%s"
}

log_template_info() {
  local -r filename="$1"
  printf "%s %s %s [%s] %s" "$(date -u +"%FT%T.%3NZ")" "${GR__LOG_ENHANCED__HOSTNAME}" "INFO" "${filename}" "%s"
}

log_template_debug() {
  local -r filename="$1"
  printf "%s %s %s [%s] %s" "$(date -u +"%FT%T.%3NZ")" "${GR__LOG_ENHANCED__HOSTNAME}" "DEBUG" "${filename}" "%s"
}
