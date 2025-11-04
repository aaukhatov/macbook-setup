#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

# import functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

info "Starting bootstrap"

sudo -v

# Start background keep-alive passing the script PID so the background job
# can detect when the main script exits and terminate itself.
_keep_sudo $$ & SUDO_PID=$!
trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT

if ask "Do you want to update macOS (it might take time to download and install)?"; then
	run sudo softwareupdate -i -a
fi

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

# if homebrew is there, continue packages installation
if command -v brew >/dev/null 2>&1; then
  run brew update
  run brew upgrade
  run brew cleanup
  run brew doctor

  if [[ -f "./Brewfile" ]] && command -v brew >/dev/null 2>&1; then
    info "Installing packages from ./Brewfile..."
    run brew bundle --file=./Brewfile
    ok "Brewfile installation complete"
  fi

  if [[ -f "./AppStore" ]] && command -v brew >/dev/null 2>&1; then
    if ask "Do you want to install packages from the AppStore?"; then
      info "Installing packages from ./AppStore..."
      run brew bundle --file=./AppStore
      ok "AppStore installation complete"
    else
      info "Skipping AppStore installation"
    fi
  fi

  # Cleanup
  run brew cleanup
  run brew doctor
else
  warn "brew not available for housekeeping"
fi

# OMZ unattended installation
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
	if ask "Do you want to install Oh My Zsh?"; then
		info "Oh My Zsh not found, installing..."
		run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	else
		info "Skipping Oh My Zsh installation"
	fi
fi

if [[ ! -d "$HOME/.sdkman" ]]; then
	if ask "Do you want to install SDKMAN?"; then
		info "Installing SDKMAN..."
		run curl -s "https://get.sdkman.io" | bash
	else
		info "Skipping SDKMAN installation"
	fi
fi

finish
exit 0
