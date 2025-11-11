#!/usr/bin/env bash

set -euo pipefail

if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
  BOLD="$(tput bold)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  RESET="$(tput sgr0)"
else
  BOLD='' RED='' GREEN='' YELLOW='' BLUE='' RESET=''
fi

info()  { printf '%s\n' "${BLUE}${BOLD}==>${RESET} $*"; }
warn()  { printf '%s\n' "${YELLOW}${BOLD}==>[!]${RESET} $*"; }
err()   { printf '%s\n' "${RED}${BOLD}==>[✗]${RESET} $*" >&2; }
ok()    { printf '%s\n' "${GREEN}${BOLD}==>[✓]${RESET} $*"; }

# If not running under bash (e.g. invoked via sh -c "..."), re-exec under bash reading stdin.
if [ -z "${BASH_VERSION-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  else
    err "bash is required to run this installer."
    exit 1
  fi
fi

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

download_github_repo() {
  local repo="$1"
  local target_dir="$2"

  if [[ -z "$repo" || -z "$target_dir" ]]; then
    err "Usage: download_github_repo <user>/<repo> <target_dir>"
    return 1
  fi

  local gh_user repo url_main url_master tmp_dir zip_path extracted_dir

  gh_user="${repo%%/*}"
  repo="${repo##*/}"

  url_main="https://github.com/${gh_user}/${repo}/archive/refs/heads/main.zip"
  url_master="https://github.com/${gh_user}/${repo}/archive/refs/heads/master.zip"

  tmp_dir="$(mktemp -d)"
  zip_path="${tmp_dir}/repo.zip"

  info "Downloading GitHub repo: ${repo}"

  # Try main.zip first, fallback to master.zip
  if ! curl -L --fail --silent --show-error "$url_main" -o "$zip_path"; then
    warn "main.zip not found, trying master..."
    if ! curl -L --fail --silent --show-error "$url_master" -o "$zip_path"; then
      err "Could not download archive from GitHub (tried main and master)."
      return 1
    fi
  fi

  info "Unzipping archive..."
  unzip -q "$zip_path" -d "$tmp_dir"

  extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "$extracted_dir" || ! -d "$extracted_dir" ]]; then
    err "Could not find extracted directory." >&2
    return 1
  fi

  info "Moving into $target_dir"
  cp -a "$extracted_dir/." "$target_dir"
	rm -rf "$tmp_dir"
  ok "Download complete: $target_dir"
}

GH_USER="aaukhatov"
GH_REPO="macbook-setup"

TARGET_DIR="${SCRIPT_DIR}/${GH_REPO}"

if [[ -d "${TARGET_DIR}" ]]; then
	warn "Existing directory found at ${TARGET_DIR}"
	read -r -p "${YELLOW}${BOLD}Do you want to remove it before re-installing? [y/N]:${RESET} " confirm
	if [[ "${confirm}" =~ ^[Yy]$ ]]; then
		info "Removing existing directory..."
		rm -rf "${TARGET_DIR}"
	else
		err "Installation aborted."
		exit 1
	fi
fi

download_github_repo ${GH_USER}/${GH_REPO} "${TARGET_DIR}"

# source the bundled bootstrap via script-relative path
source "${TARGET_DIR}/bootstrap.sh"
