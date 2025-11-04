#!/usr/bin/env bash

set -euo pipefail

# If not running under bash (e.g. invoked via sh -c "..."), re-exec under bash reading stdin.
if [ -z "${BASH_VERSION-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash -s -- "$@"
  else
    echo "bash is required to run this installer." >&2
    exit 1
  fi
fi

download_github_repo() {
  local repo="$1"
  local target_dir="$2"

  if [[ -z "$repo" || -z "$target_dir" ]]; then
    echo "Usage: download_github_repo <user>/<repo> <target_dir>" >&2
    return 1
  fi

  local gh_user repo url_main url_master tmp_dir zip_path extracted_dir

  gh_user="${repo%%/*}"
  repo="${repo##*/}"

  url_main="https://github.com/${gh_user}/${repo}/archive/refs/heads/main.zip"
  url_master="https://github.com/${gh_user}/${repo}/archive/refs/heads/master.zip"

  tmp_dir="$(mktemp -d)"
  zip_path="${tmp_dir}/repo.zip"

  echo "==>[*] Downloading GitHub repo: ${repo}"

  # Try main.zip first, fallback to master.zip
  if ! curl -L --fail --silent --show-error "$url_main" -o "$zip_path"; then
    echo "==>[!] main.zip not found, trying master..."
    if ! curl -L --fail --silent --show-error "$url_master" -o "$zip_path"; then
      echo "❌ Could not download archive from GitHub (tried main and master)." >&2
      return 1
    fi
  fi

  echo "==>[*] Unzipping archive..."
  unzip -q "$zip_path" -d "$tmp_dir"

  extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "$extracted_dir" || ! -d "$extracted_dir" ]]; then
    err "❌ Could not find extracted directory." >&2
    return 1
  fi

  echo "==>[*] Moving into $target_dir"
  mv "$extracted_dir" "$target_dir"
	rm -rf "$tmp_dir"
  echo "==>[*] Download complete: $target_dir"
}

GH_USER="aaukhatov"
GH_REPO="macbook-setup"

download_github_repo $GH_USER/$GH_REPO "$(pwd)/$GH_REPO"
