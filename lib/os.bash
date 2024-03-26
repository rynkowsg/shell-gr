#!/usr/bin/env bash
# Copyright (c) 2024. All rights reserved.
# License: MIT License

linux_id() {
  # shellcheck disable=SC2002
  cat /etc/os-release | grep -w ID | cut -d '=' -f 2
}
