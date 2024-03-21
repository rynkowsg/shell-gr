#!/usr/bin/env bash

is_git_repository() {
  git rev-parse --git-dir >/dev/null 2>&1
}
