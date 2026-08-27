#!/usr/bin/env bash
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
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
source "${_SHELL_GR_DIR}/lib/debug.bash"                 # is_debug
source "${_SHELL_GR_DIR}/lib/error.bash"                 # fail
source "${_SHELL_GR_DIR}/lib/install/common/github.bash" # GRIC_GH_latest_stable, GRIC_GH_list_github_tags, GRIC_GH_sort_versions
source "${_SHELL_GR_DIR}/lib/log.bash"                   # log_debug, log_info
source "${_SHELL_GR_DIR}/lib/temp.bash"                  # temp_dir
source "${_SHELL_GR_DIR}/lib/trap.bash"                  # add_on_exit

# shellcheck disable=SC2034
GH_REPO="https://github.com/CircleCI-Public/circleci-cli"
TOOL_NAME="circleci"
TOOL_TEST="circleci --help"
# The release assets are named after the repository, not after the binary they carry.
ASSET_NAME="circleci-cli"

# Splits "MAJOR.MINOR.PATCH" and tells whether it belongs to the 0.1 line.
# The 0.1 line is where both the archive layout and the binary name changed.
GRI_CIRCLECI_CLI__is_v0_line() {
  local -r version="$1"
  local major minor
  IFS=. read -r major minor _ <<<"${version}"
  [ "${major}" = "0" ] && [ "${minor}" = "1" ]
}

# Releases from 0.1.390 to 0.1.38646 pack everything into a
# "circleci-cli_<version>_<os>_<arch>" directory. Everything before and after
# keeps the files at the root of the archive.
GRI_CIRCLECI_CLI__has_wrapped_archive() {
  local -r version="$1"
  # patches of 0.1.390 and 0.1.38646, the first and the last wrapped release
  local -r first_wrapped_patch=390
  local -r last_wrapped_patch=38646
  local patch
  IFS=. read -r _ _ patch <<<"${version}"
  GRI_CIRCLECI_CLI__is_v0_line "${version}" \
    && [ "${patch}" -ge "${first_wrapped_patch}" ] \
    && [ "${patch}" -le "${last_wrapped_patch}" ]
}

# Up to 0.1.160 the binary is called "circleci-beta". 0.1.47860, which ships the
# legacy v0 CLI next to the 1.0 line, calls it "circleci-v0". Everywhere else it
# is "circleci".
GRI_CIRCLECI_CLI__archived_binary_name() {
  local -r version="$1"
  # patch of 0.1.160, the last release shipping the binary under the beta name
  local -r last_beta_patch=160
  local patch
  IFS=. read -r _ _ patch <<<"${version}"
  if GRI_CIRCLECI_CLI__is_v0_line "${version}" && [ "${patch}" -le "${last_beta_patch}" ]; then
    printf "%s" "${TOOL_NAME}-beta"
  elif [ "${version}" = "0.1.47860" ]; then
    printf "%s" "${TOOL_NAME}-v0"
  else
    printf "%s" "${TOOL_NAME}"
  fi
}

GRI_CIRCLECI_CLI__list_deps() {
  initial_deps=()
  initial_deps+=(sort uniq)           # GRI_CIRCLECI_CLI__list_deps
  initial_deps+=(curl tar)            # GRI_CIRCLECI_CLI__download
  initial_deps+=(git grep cut sed)    # GRIC_GH_list_github_tags
  initial_deps+=(sed sort awk)        # GRIC_GH_sort_versions
  initial_deps+=(curl sed tail xargs) # GRIC_GH_latest_stable
  mapfile -t deps < <(printf "%s\n" "${initial_deps[@]}" | sort | uniq)
  for item in "${deps[@]}"; do
    printf "%s\n" "${item}"
  done
}

GRI_CIRCLECI_CLI__list_all_versions() {
  # inputs
  local -r gh_repo="${GH_REPO}"
  # tagged, but no release was ever published under it, so nothing can be downloaded
  local -r unreleased_version="0.1.47632"
  # body
  # The repo holds tags that are not releases of this tool, e.g. "clikit/v1.0.48773"
  # tagging a separate library, or one-off tags like "test-abraham". Keep only tags
  # that are a plain MAJOR.MINOR.PATCH version, then drop the one that never got
  # a release.
  GRIC_GH_list_github_tags "${gh_repo}" \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | grep -vxF "${unreleased_version}" \
    | GRIC_GH_sort_versions
}
#GRI_CIRCLECI_CLI__list_all_versions

GRI_CIRCLECI_CLI__latest_stable() {
  # inputs
  local -r gh_repo="${GH_REPO}"
  local -r github_api_token="${GITHUB_API_TOKEN:-}" # optional
  # body
  GITHUB_API_TOKEN="${github_api_token}" \
    GRIC_GH_latest_stable "${gh_repo}"
}
#GRI_CIRCLECI_CLI__latest_stable

GRI_CIRCLECI_CLI__compose_download_url() {
  local version="$1"
  local platform_uname platform
  platform_uname="$(uname -s)"
  case "${platform_uname}" in
    Linux*) platform="linux" ;;
    Darwin*) platform="darwin" ;;
    *) fail "Platform \"${platform_uname}\" is not yet supported." ;;
  esac

  local uname_arch arch
  uname_arch="$(uname -m)"
  case "${uname_arch}" in
    aarch64 | arm64) arch="arm64" ;;
    x86_64) arch="amd64" ;;
    *) fail "Architecture \"${uname_arch}\" is not yet supported." ;;
  esac
  # possible values:
  # https://stackoverflow.com/questions/45125516/possible-values-for-uname-m

  # releases: https://github.com/CircleCI-Public/circleci-cli/releases
  # sample URL: https://github.com/CircleCI-Public/circleci-cli/releases/download/v0.1.33163/circleci-cli_0.1.33163_linux_amd64.tar.gz
  local download_url="${GH_REPO}/releases/download/v${version}/${ASSET_NAME}_${version}_${platform}_${arch}.tar.gz"
  printf "%s" "${download_url}"
}
#GRI_CIRCLECI_CLI__compose_download_url "0.1.33163"

GRI_CIRCLECI_CLI__download() {
  # inputs
  local -r type="${GRI_CIRCLECI_CLI__INSTALL_TYPE:-}"
  local -r version="${GRI_CIRCLECI_CLI__INSTALL_VERSION:-}"
  local -r dest="${GRI_CIRCLECI_CLI__DOWNLOAD_PATH:-}"
  local -r github_api_token="${GRI_CIRCLECI_CLI__GITHUB_API_TOKEN:-}" # optional

  # inputs validation
  [ "${type}" != "version" ] && fail "Only installation by version is supported."
  [ -z "${version}" ] && fail "version can't be empty"
  [ -z "${dest}" ] && fail "destination can't be empty"

  # prepare temp directory
  local temp_dir
  temp_dir=$(mktemp -d -t "shell-gr-install-${TOOL_NAME}-tmp-download-dir.XXXX")
  log_debug "Temporary directory created at ${temp_dir}"
  ! is_debug && add_on_exit rm -rf "${temp_dir}"
  log_debug

  # prepare curl opts
  local curl_opts=(
    -L #  follow redirects
  )
  if [ -n "${github_api_token:-}" ]; then
    curl_opts=("${curl_opts[@]}" "-H" "Authorization: token ${github_api_token}")
  fi

  # download archive
  # circleci-cli publishes one combined checksums file per release instead of a
  # checksum file per asset, so there is no per-asset checksum to verify against
  log_info "Downloading ${TOOL_NAME} release ${version}..."
  local archive_url
  archive_url="$(GRI_CIRCLECI_CLI__compose_download_url "${version}")"
  log_info " - ${archive_url}"
  local temp_archive_path="${temp_dir}/${TOOL_NAME}.tar.gz"
  curl "${curl_opts[@]}" -o "${temp_archive_path}" -C - "${archive_url}" || fail "Could not download ${archive_url}"
  log_info

  # move the downloaded file to final destination
  mkdir -p "${dest}"
  local tar_opts=(-xzf "${temp_archive_path}" -C "${dest}")
  # An older archive wraps everything in a
  # "${ASSET_NAME}_${version}_${platform}_${arch}" directory, so strip it to get
  # the binary straight into ${dest}. A newer one keeps the files at the root,
  # where stripping a component would throw the binary away.
  if GRI_CIRCLECI_CLI__has_wrapped_archive "${version}"; then
    tar_opts+=(--strip-components=1)
  fi
  is_debug && tar_opts+=(-v)
  tar "${tar_opts[@]}" || fail "Could not extract ${temp_archive_path}"

  # Install the legacy v0 binary under the regular name, so that the command is
  # called "${TOOL_NAME}" whichever version was picked.
  local archived_binary
  archived_binary="$(GRI_CIRCLECI_CLI__archived_binary_name "${version}")"
  if [ "${archived_binary}" != "${TOOL_NAME}" ]; then
    mv "${dest}/${archived_binary}" "${dest}/${TOOL_NAME}" \
      || fail "Could not find ${archived_binary} in ${temp_archive_path}"
  fi

  log_info "Downloading ${TOOL_NAME} release ${version}... DONE"
  log_info
}
#rm -rf /tmp/tmp-circleci-download-dir
#GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
#  GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.33163" \
#  GRI_CIRCLECI_CLI__DOWNLOAD_PATH="/tmp/tmp-circleci-download-dir" \
#  GRI_CIRCLECI_CLI__GITHUB_API_TOKEN="$(pass show rynkowski/github/rynkowsg/token/release_download_token)" \
#  GRI_CIRCLECI_CLI__download

GRI_CIRCLECI_CLI__install_downloaded() {
  # inputs
  local -r type="${GRI_CIRCLECI_CLI__INSTALL_TYPE:-}"
  local -r version="${GRI_CIRCLECI_CLI__INSTALL_VERSION:-}"
  local -r download_path="${GRI_CIRCLECI_CLI__DOWNLOAD_PATH:-}"
  local -r install_path="${GRI_CIRCLECI_CLI__INSTALL_PATH:-}"

  # inputs validation
  [ "${type}" != "version" ] && fail "Only installation by version is supported."
  [ -z "${version}" ] && fail "version can't be empty"
  [ -z "${download_path}" ] && fail "download path can't be empty"
  [ -z "${install_path}" ] && fail "install path can't be empty"

  (
    mkdir -p "${install_path}"
    cp -r "${download_path}"/* "${install_path}"

    # test the command is installed
    local tool_cmd
    tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)" # actually take only the first param
    test -x "${install_path}/${tool_cmd}" || fail "Expected ${install_path}/${tool_cmd} to be executable."

    log_info "${TOOL_NAME} ${version} installation was successful!"
  ) || (
    rm -rf "${install_path}"
    fail "An error occurred while installing ${TOOL_NAME} ${version}."
  )
}
#rm -rf /tmp/tmp-circleci-install-dir
#GRI_CIRCLECI_CLI__INSTALL_TYPE="version" \
#  GRI_CIRCLECI_CLI__INSTALL_VERSION="0.1.33163" \
#  GRI_CIRCLECI_CLI__DOWNLOAD_PATH="/tmp/tmp-circleci-download-dir" \
#  GRI_CIRCLECI_CLI__INSTALL_PATH="/tmp/tmp-circleci-install-dir" \
#  GRI_CIRCLECI_CLI__install_downloaded
#/tmp/tmp-circleci-install-dir/circleci version

# Installs circleci-cli using the specified version.
# Basically it runs under the hood two functions:
# - GRI_CIRCLECI_CLI__download &
# - GRI_CIRCLECI_CLI__install_downloaded
GRI_CIRCLECI_CLI__install() {
  # inputs
  local -r type="${GRI_CIRCLECI_CLI__INSTALL_TYPE:-}"
  local -r version="${GRI_CIRCLECI_CLI__INSTALL_VERSION:-}"
  local -r install_path="${GRI_CIRCLECI_CLI__INSTALL_PATH:-}"
  local -r github_api_token="${GITHUB_API_TOKEN:-}" # optional

  # inputs validation
  [ "${type}" != "version" ] && fail "asdf-${TOOL_NAME} supports release installs only"
  [ -z "${version}" ] && fail "version can't be empty"
  [ -z "${install_path}" ] && fail "install path can't be empty"

  local download_path
  download_path="$(temp_dir "shell-gr-install-${TOOL_NAME}")"
  log_debug "Directory to store downloaded files created at ${download_path}"
  ! is_debug && add_on_exit rm -rf "${download_path}"

  GRI_CIRCLECI_CLI__INSTALL_TYPE="${type}" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="${version}" \
    GRI_CIRCLECI_CLI__DOWNLOAD_PATH="${download_path}" \
    GITHUB_API_TOKEN="${github_api_token}" \
    GRI_CIRCLECI_CLI__download

  GRI_CIRCLECI_CLI__INSTALL_TYPE="${type}" \
    GRI_CIRCLECI_CLI__INSTALL_VERSION="${version}" \
    GRI_CIRCLECI_CLI__INSTALL_PATH="${install_path}" \
    GRI_CIRCLECI_CLI__DOWNLOAD_PATH="${download_path}" \
    GRI_CIRCLECI_CLI__install_downloaded
}
