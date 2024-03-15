#!/usr/bin/env bash

# Problem
# Trap helps to clean up in case script exist either successfully or by some
# sort of failure. The limitation is that you can use only one trap statement
# per script. Having two, the second one overrides the first.
#
# Solution
# `add_on_exit` is a wrapper for `trap` allowing to perform multiple actions
# with trap on event of EXIT or INT.

declare -a _ON_EXIT_ITEMS=()

on_exit() {
  for i in "${_ON_EXIT_ITEMS[@]}"; do
    eval "$i"
  done
}

add_on_exit() {
  local -r n=${#_ON_EXIT_ITEMS[*]}
  _ON_EXIT_ITEMS[n]="$*"
  # set the trap only the first time
  if [[ $n -eq 0 ]]; then
    trap on_exit EXIT INT
  fi
}
