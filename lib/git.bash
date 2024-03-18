#!/usr/bin/env bash

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
else
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ ^(/bin/)?(ba)?sh$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash" # GREEN, NC, RED

setup_git_lfs() {
  local -r lfs_enabled="$1"
  printf "${GREEN}%s${NC}\n" "Setting up Git LFS"
  if ! which git-lfs >/dev/null && [ "${lfs_enabled}" = 0 ]; then
    printf "%s\n" "git-lfs is not installed, but also it's not needed. Nothing to do here."
  elif ! which git-lfs >/dev/null && [ "${lfs_enabled}" = 1 ]; then
    printf "${GREEN}%s${NC}\n" "Installing Git LFS..."
    curl -sSL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt-get install -y git-lfs
    printf "${GREEN}%s${NC}\n\n" "Installing Git LFS... DONE"
  elif which git-lfs >/dev/null && [ "${lfs_enabled}" = 0 ]; then
    if [ -f /etc/gitconfig ] && git config --list --system | grep -q "filter.lfs"; then
      sudo git lfs uninstall --system
    fi
    if git config --list --global | grep -q "filter.lfs"; then
      git lfs uninstall
    fi
  elif which git-lfs >/dev/null && [ "${lfs_enabled}" = 1 ]; then
    git lfs install
  else
    printf "${RED}%s${NC}\n" "This should never happen"
    exit 1
  fi
  printf "%s\n" ""
}

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
