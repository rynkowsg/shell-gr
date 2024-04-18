#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

is_git_repository() {
  git rev-parse --git-dir >/dev/null 2>&1
}
