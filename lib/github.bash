#!/usr/bin/env bash

# Returns GitHub authorized URL if github token provided.
# Otherwise returns same URL.
# Params:
# $1 - repo url
# $2 - github token
github_authorized_repo_url() {
  local repo_url="${1}"
  local github_token="${2}"
  if [[ $repo_url == "https://github.com"* ]] && [[ -n "${github_token}" ]]; then
    echo "https://${github_token}@${repo_url#https://}"
  else
    echo "${repo_url}"
  fi
}
