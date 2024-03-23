#!/usr/bin/env bash

# Path Initialization
if [ -n "${SHELL_GR_DIR}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
else
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
source "${_SHELL_GR_DIR}/lib/color.bash" # GREEN, NC, RED, YELLOW
source "${_SHELL_GR_DIR}/lib/git.bash"   # is_git_repository

# $1 - dest
git_checkout_advanced() {
  local -r input_DEBUG="${GR_GITCO__DEBUG:-}"
  local -r input_DEBUG_GIT="${GR_GITCO__DEBUG_GIT:-}"
  local -r input_DEPTH="${GR_GITCO__DEPTH:-}"
  local -r input_DEST_DIR="${GR_GITCO__DEST_DIR:-}"
  local -r input_LFS_ENABLED="${GR_GITCO__LFS_ENABLED:-}"
  local -r input_REPO_BRANCH="${GR_GITCO__REPO_BRANCH:-}"
  local -r input_REPO_SHA1="${GR_GITCO__REPO_SHA1:-}"
  local -r input_REPO_TAG="${GR_GITCO__REPO_TAG:-}"
  local -r input_REPO_URL="${GR_GITCO__REPO_URL:-}"
  local -r input_SUBMODULES_DEPTH="${GR_GITCO__SUBMODULES_DEPTH:-}"
  local -r input_SUBMODULES_ENABLED="${GR_GITCO__SUBMODULES_ENABLED:-}"

  local -r debug="${input_DEBUG}"
  local -r depth="${input_DEPTH}"
  local -r debug_git="${input_DEBUG_GIT}"
  local -r dest="${input_DEST_DIR}"
  local -r lfs_enabled="${input_LFS_ENABLED}"
  local -r repo_branch="${input_REPO_BRANCH}"
  local -r repo_tag="${input_REPO_TAG}"
  local -r repo_sha1="${input_REPO_SHA1}"
  local repo_url
  repo_url="$(github_authorized_repo_url "${input_REPO_URL}" "${GITHUB_TOKEN}")"
  if [[ "${repo_url}" != "${input_REPO_URL}" ]]; then
    printf "${GREEN}%s${NC}\n" "Detected GitHub token. Update:"
    printf "%s\n" "- repo_url: ${repo_url}"
  fi
  readonly repo_url
  local -r submodules_enabled="${input_SUBMODULES_ENABLED}"
  local -r submodules_depth="${input_SUBMODULES_DEPTH}"

  # To facilitate cloning shallow repo for branch, tag or particular sha,
  # we don't use `git clone`, but combination of `git init` & `git fetch`.
  printf "${GREEN}%s${NC}\n" "Establishing git repo..."
  printf "%s\n" "- repo_url: ${repo_url}"
  printf "%s\n" "- dst: ${dest}"
  printf "%s\n" ""

  # --- check dest directory
  mkdir -p "${dest}"
  if [ "$(ls -A "${dest}")" ]; then
    printf "${YELLOW}%s${NC}\n" "Directory \"${dest}\" is not empty."
    ls -Al "${dest}"
    printf "%s\n" ""
  fi
  # --- init repo
  cd "${dest}" || error_exit "Can't enter destination directory: '${dest}'"
  # Skip smudge to download binary files later in a faster batch
  [ "${lfs_enabled}" = 1 ] && git lfs install --skip-smudge
  # --skip-smudge

  if is_git_repository; then
    git remote set-url origin "${repo_url}"
  else
    git init
    git remote add origin "${repo_url}"
  fi
  [ "${lfs_enabled}" = 1 ] && git lfs install --local --skip-smudge
  if [ "${debug_git}" = 1 ]; then
    if [ "${lfs_enabled}" = 1 ]; then
      printf "${YELLOW}%s${NC}\n" "[LOGS] git lfs env"
      git lfs env
    fi
    printf "${YELLOW}%s${NC}\n" "[LOGS] git config -l"
    [ -f /etc/gitconfig ] && git config --list --system | sort
    git config --list --global | sort
    git config --list --worktree | sort
    git config --list --local | sort
  fi
  printf "%s\n" ""

  fetch_params=()
  [ "${depth}" -ne -1 ] && fetch_params+=("--depth" "${depth}")
  fetch_params_serialized="$(
    IFS=,
    echo "${fetch_params[*]}"
  )"
  # create fetch_repo_script
  local fetch_repo_script
  fetch_repo_script="$(create_fetch_repo_script)"
  # start checkout
  if [ -n "${repo_tag}" ]; then
    printf "${GREEN}%s${NC}\n" "Fetching & checking out tag..."
    git fetch "${fetch_params[@]}" origin "refs/tags/${repo_tag}:refs/tags/${repo_tag}"
    git -c advice.detachedHead=false checkout --force "${repo_tag}"
    git reset --hard "${repo_sha1}"
  elif [ -n "${repo_branch}" ] && [ -n "${repo_sha1}" ]; then
    printf "${GREEN}%s${NC}\n" "Fetching & checking out branch..."
    DEBUG="${debug}" \
      TMP__FETCH_PARAMS_SERIALIZED="${fetch_params_serialized}" \
      TMP__REFSPEC="refs/heads/${repo_branch}:refs/remotes/origin/${repo_branch}" \
      TMP__BRANCH="${repo_branch}" \
      TMP__SHA1="${repo_sha1}" \
      bash "${fetch_repo_script}"
  else
    printf "${RED}%s${NC}\n" "Missing coordinates to clone the repository."
    printf "${RED}%s${NC}\n" "Need to specify REPO_TAG to fetch by tag or REPO_BRANCH and REPO_SHA1 to fetch by branch."
    exit 1
  fi
  submodule_update_params=("--init" "--recursive")
  [ "${submodules_depth}" -ne -1 ] && submodule_update_params+=("--depth" "${submodules_depth}")
  [ "${submodules_enabled}" = 1 ] && git submodule update "${submodule_update_params[@]}"
  if [ "${lfs_enabled}" = 1 ]; then
    git lfs pull
    if [ "${submodules_enabled}" = 1 ]; then
      local fetch_lfs_in_submodule
      fetch_lfs_in_submodule="$(mktemp -t "checkout-fetch_lfs_in_submodule-$(date +%Y%m%d_%H%M%S)-XXXXX")"
      # todo: add cleanup
      cat <<-EOF >"${fetch_lfs_in_submodule}"
if [ -f .gitattributes ] && grep -q "filter=lfs" .gitattributes; then
  git lfs install --local --skip-smudge
  git lfs pull
else
  echo "Skipping submodule without LFS or .gitattributes"
fi
EOF
      git submodule foreach --recursive "bash \"${fetch_lfs_in_submodule}\""
    fi
  fi
  printf "%s\n" ""

  printf "${GREEN}%s${NC}\n" "Summary"
  git --no-pager log --no-color -n 1 --format="HEAD is now at %h %s"
  printf "%s\n" ""
}

create_fetch_repo_script() {
  local fetch_repo_script
  fetch_repo_script="$(mktemp -t "checkout-fetch_repo-$(date +%Y%m%d_%H%M%S)-XXXXX")"
  # todo: add cleanup
  cat <<-'EOF' >"${fetch_repo_script}"
DEBUG=${DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

fetch_repo() {
  local -r fetch_params_serialized="${TMP__FETCH_PARAMS_SERIALIZED}"
  local -r refspec="${TMP__REFSPEC}"
  local -r branch="${TMP__BRANCH}"
  local -r sha1="${TMP__SHA1}"

  IFS=',' read -r -a fetch_params <<< "${fetch_params_serialized}"

  # Find depth in fetch_params
  local depth_specified=0
  local depth=
  for ((i = 0; i < ${#fetch_params[@]}; i++)); do
    if [[ ${fetch_params[i]} == "--depth" ]]; then
      depth_specified=1
      depth=${fetch_params[i+1]}
    fi
  done

  # fetch
  git fetch "${fetch_params[@]}" origin "${refspec}"

  local checkout_error checkout_status
  # Try to checkout
  checkout_error=$(git checkout --force -B "${branch}" "${sha1}" 2>&1)
  checkout_status=$?

  if [ ${checkout_status} -eq 0 ]; then
    message=$([ ${depth_specified} == 0 ] && echo "Full checkout succeeded." || echo "Shallow checkout succeeded.")
    printf "${GREEN}%s${NC}\n" "${message}"
  else
    printf "${RED}%s${NC}\n" "Checkout failed with status: ${checkout_status}"
    if [[ $checkout_error == *"is not a commit and a branch"* ]]; then
      printf "${RED}%s${NC}\n" "Commit not found, deepening..."
      local commit_found=false
      # Deepen the clone until the commit is found or a limit is reached
      for i in {1..10}; do
        printf "${YELLOW}%s${NC}\n" "Deepening attempt ${i}: by 10 commits"
        git fetch --deepen 10
        # Try to checkout again
        checkout_error=$(git checkout --force -B "${branch}" "${sha1}" 2>&1)
        checkout_status=$?
        if [ $checkout_status -eq 0 ]; then
          printf "${GREEN}%s${NC}\n" "Checkout succeeded after deepening."
          commit_found=true
          break
        elif [[ $checkout_error == *"is not a commit and a branch"* ]]; then
          # same error, commit still not found
          :
        else
          # If the error is not about the commit being missing, break the loop
          printf "${RED}%s${NC}\n" "Checkout failed with an unexpected error: $checkout_error"
          break
        fi
      done

      if [[ $commit_found != true ]]; then
        printf "${RED}%s${NC}\n" "Failed to find commit after deepening. Fetching the full history..."
        git fetch --unshallow
        checkout_error=$(git checkout --force -B "${branch}" "${sha1}")
        checkout_status=$?
        if [ $checkout_status -eq 0 ]; then
          printf "${GREEN}%s${NC}\n" "Checkout succeeded after full fetch."
        else
          printf "${RED}%s${NC}\n" "Full checkout failed."
          exit ${checkout_status}
        fi
      fi

    else
      echo "Checkout failed with an unexpected error: $checkout_error"
      exit 1
    fi
  fi
}

fetch_repo
EOF
  echo "${fetch_repo_script}"
}
