#!/usr/bin/env bash

set -euo pipefail
set -o vi
# temporarily disable errexit, run best-effort command, check result, restore errexit
# set +e
IFS=$'\n\t'

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

run_best_effort() {
  info "Running (best-effort): $*"
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
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done
}

_keep_sudo & SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null || true' EXIT

run_best_effort sudo softwareupdate -i -a

# Install Rosetta only on Apple Silicon (best-effort)
if [[ "$(uname -m)" == "arm64" ]]; then
  if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
    run_best_effort sudo softwareupdate --install-rosetta --agree-to-license
  else
    info "Rosetta already running"
  fi
fi

# Install Xcode Command Line Tools if missing
if ! xcode-select -p >/dev/null 2>&1; then
  info "Installing Xcode Command Line Tools..."
  run_best_effort sudo xcode-select --install
  info "Waiting for Xcode CLT to be ready..."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 10
  done
  ok "Xcode Command Line Tools installed"
else
  info "Xcode Command Line Tools already installed"
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  run_best_effort /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Append Homebrew initialization to .zprofile
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>${HOME}/.zprofile
	# Immediately evaluate the Homebrew environment settings for the current session
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew present"
fi

# Homebrew housekeeping (best-effort)
if command -v brew >/dev/null 2>&1; then
  run_best_effort brew update
  run_best_effort brew upgrade
  run_best_effort brew cleanup
  run_best_effort brew doctor
else
  warn "brew not available for housekeeping"
fi

if [[ -f "./Brewfile" ]] && command -v brew >/dev/null 2>&1; then
  info "Installing packages from ./Brewfile..."
  run_best_effort brew bundle --file=./Brewfile
  ok "Brewfile installation complete"
fi

ok "Bootstrap finished"

# Cleanup
run_best_effort brew cleanup
run_best_effort brew doctor
