#!/usr/bin/env bash

declare -a ON_EXIT_ITEMS=()

on_exit() {
  for i in "${ON_EXIT_ITEMS[@]}"; do
    eval "$i"
  done
}

add_on_exit() {
  local -r n=${#ON_EXIT_ITEMS[*]}
  ON_EXIT_ITEMS[n]="$*"
  # set the trap only the first time
  if [[ $n -eq 0 ]]; then
    trap on_exit EXIT
  fi
}
