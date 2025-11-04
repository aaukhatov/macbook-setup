#!/usr/bin/env bash

set -euo pipefail
# temporarily disable errexit, run best-effort command, check result, restore errexit
# set +e
IFS=$'\n\t'

# import functions
source ./utils.sh

info "Starting bootstrap"

sudo -v

# Start background keep-alive passing the script PID so the background job
# can detect when the main script exits and terminate itself.
_keep_sudo $$ & SUDO_PID=$!
trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT

run sudo softwareupdate -i -a

# Install Rosetta only on Apple Silicon (best-effort)
if [[ "$(uname -m)" == "arm64" ]]; then
  if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
  	info "Installing Rosetta..."
    run sudo softwareupdate --install-rosetta --agree-to-license
  else
    info "Rosetta already running"
  fi
fi

# Install Xcode Command Line Tools if missing
if ! xcode-select -p >/dev/null 2>&1; then
  info "Installing Xcode Command Line Tools..."
  run sudo xcode-select --install
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
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Append Homebrew initialization to .zprofile
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>${HOME}/.zprofile
	# Immediately evaluate the Homebrew environment settings for the current session
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew present"
fi

# Homebrew housekeeping (best-effort)
if command -v brew >/dev/null 2>&1; then
  run brew update
  run brew upgrade
  run brew cleanup
  run brew doctor
else
  warn "brew not available for housekeeping"
fi

if [[ -f "./Brewfile" ]] && command -v brew >/dev/null 2>&1; then
  info "Installing packages from ./Brewfile..."
  run brew bundle --file=./Brewfile
  ok "Brewfile installation complete"
fi

# Cleanup
run brew cleanup
run brew doctor

# OMZ unattended installation
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
	info "Oh My Zsh not found, installing..."
	run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [[ ! -d "$HOME/.sdkman" ]]; then
	info "Installing SDKMAN..."
	run curl -s "https://get.sdkman.io" | bash
fi

finish
exit 0
