#!/usr/bin/env bash
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

is_git_repository() {
  git rev-parse --git-dir >/dev/null 2>&1
}

# Succeeds when the current directory is the root of a repo, not just somewhere inside one.
is_git_repository_root_dir() {
  is_git_repository && [ "$(git rev-parse --show-toplevel)" = "$(pwd -P)" ]
}
