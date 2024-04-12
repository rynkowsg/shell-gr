#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/../.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/error.bash" # assert_not_empty

GRIC_GH_sort_versions() {
  # input: version lists on stdin
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' \
    | LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n \
    | awk '{print $2}'
}

GRIC_GH_list_github_tags() {
  # inputs
  local -r gh_repo="${1:-}"
  # inputs validation
  assert_not_empty gh_repo
  # body
  git ls-remote --tags --refs "${gh_repo}" \
    | grep -o 'refs/tags/.*' \
    | cut -d/ -f3- \
    | sed 's/^v//'
}

GRIC_GH_list_all_versions() {
  # inputs
  local -r gh_repo="${1:-}"
  # inputs validation
  assert_not_empty gh_repo
  # body
  GRIC_GH_list_github_tags "${gh_repo}" | GRIC_GH_sort_versions
}

GRIC_GH_latest_stable() {
  # inputs
  local -r gh_repo="${1:-}"
  local -r github_api_token="${GITHUB_API_TOKEN:-}" # optional

  # inputs validation
  assert_not_empty gh_repo

  local curl_opts=(--silent --head)
  # If GITHUB_API_TOKEN defined, add it request headers
  # Not authorized user has certain quota for making API request to Github.
  # If user provides in environment GITHUB_API_TOKEN, can lift it up.
  if [ -n "${github_api_token:-}" ]; then
    curl_opts=("${curl_opts[@]}" -H "Authorization: token ${github_api_token}")
  fi

  # By default try to get the latest from github latest URL.
  # It is done with curl. When it requests REPO/releases/latest, it expects to receive 302 to another URL.
  # This value is saved at redirect_url.
  # - if (redirect_url = "REPO/releases/tag/v<VERSION>"), then take such a VERSION
  # - otherwise (redirect_url == "REPO/releases"), then take the latest based on list of versions.
  local version redirect_url
  redirect_url=$(curl "${curl_opts[@]}" "${gh_repo}/releases/latest" | sed -n -e "s|^location: *||p" | sed -n -e "s|\r||p")
  log_debug_f "redirect url: %s\n" "${redirect_url}"
  if [[ "${redirect_url}" != "${gh_repo}/releases" ]]; then
    version="$(printf "%s\n" "${redirect_url}" | sed 's|.*/tag/v\{0,1\}||')"
  else
    version="$(GRIC_GH_list_all_versions "${gh_repo}" | GRIC_GH_sort_versions | tail -n1 | xargs echo)"
  fi

  printf "%s\n" "${version}"
}
