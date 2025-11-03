#!/usr/bin/env bash

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
warn()  { printf '%s\n' "${YELLOW}${BOLD}WARN:${RESET} $*"; }
err()   { printf '%s\n' "${RED}${BOLD}ERROR:${RESET} $*" >&2; }
ok()    { printf '%s\n' "${GREEN}${BOLD}OK:${RESET} $*"; }

run() {
  info "Running: $*"
  set +e
  "$@"
  rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    warn "Command exited $rc but continuing: $*"
  else
    ok "Succeeded: $*"
  fi
  return 0
}

# Ensure macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This script is macOS-only."
  exit 1
fi

info "Starting bootstrap"

sudo -v

_keep_sudo() {
  # Accept the PID of the parent process (the main script) so the background
  # refresher can detect when the script exits. We must ignore sudo errors
  # (sudo -n returns non-zero when a password is required) so the global
  # "set -e" doesn't cause the script to exit.
  local parent_pid="$1"
  while true; do
    # Refresh sudo timestamp; ignore any errors
    sudo -n true 2>/dev/null || true
    sleep 60
    # If the parent process no longer exists, exit the loop
    if ! kill -0 "${parent_pid}" 2>/dev/null; then
      exit 0
    fi
  done
}

finish() {
  local user_name
  if user_name=$(id -un 2>/dev/null); then
    :
  elif user_name=$(whoami 2>/dev/null); then
    :
  else
    user_name="${USER:-friend}"
  fi

  printf '\n'
  printf '%s\n' " ${GREEN}${BOLD} Setup complete — enjoy, ${user_name}! 🎉🎉🎉 ${RESET}"
  printf '%s\n' " ${BLUE}────────────────────────────────────────${RESET}"
  printf '%s\n' " ${GREEN}  ✅  Your favourite tools installed!${RESET}"
  printf '%s\n' " ${YELLOW}  • Tip: run command source ~/.zshrc or open a new terminal to load shell changes${RESET}"
  printf '%s\n' " ${BLUE}────────────────────────────────────────${RESET}"
  printf '%s\n' " ${GREEN}${BOLD} You're ready to rock 🤘 time to build something awesome 🚀 ${RESET}"
  printf '\n'
}

download_github_repo() {
  local repo="$1"
  local target_dir="$2"

  if [[ -z "$repo" || -z "$target_dir" ]]; then
    echo "Usage: download_github_repo <user>/<repo> <target_dir>" >&2
    return 1
  fi

  local username repo url_main url_master tmp_dir zip_path extracted_dir

  username="${repo%%/*}"
  repo="${repo##*/}"

  url_main="https://github.com/${username}/${repo}/archive/refs/heads/main.zip"
  url_master="https://github.com/${username}/${repo}/archive/refs/heads/master.zip"

  tmp_dir="$(mktemp -d)"
  zip_path="${tmp_dir}/repo.zip"

  cleanup() {
    rm -rf "$tmp_dir"
  }
  trap cleanup EXIT

  echo "[*] Downloading GitHub repo: ${repo}"

  # Try main.zip first, fallback to master.zip
  if ! curl -L --fail --silent --show-error "$url_main" -o "$zip_path"; then
    echo "[!] main.zip not found, trying master..."
    if ! curl -L --fail --silent --show-error "$url_master" -o "$zip_path"; then
      echo "❌ Could not download archive from GitHub (tried main and master)." >&2
      return 1
    fi
  fi

  echo "[*] Unzipping archive..."
  unzip -q "$zip_path" -d "$tmp_dir"

  extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "$extracted_dir" || ! -d "$extracted_dir" ]]; then
    echo "❌ Could not find extracted directory." >&2
    return 1
  fi

  if [[ -e "$target_dir" ]]; then
    echo "❌ Target path '$target_dir' already exists." >&2
    return 1
  fi

  echo "[*] Moving into $target_dir"
  mv "$extracted_dir" "$target_dir"

  echo "✅ Download complete: $target_dir"
}
