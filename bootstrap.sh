#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

# import functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

info "Starting macOS setup..."

# Ensure macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This script is macOS-only."
  exit 1
fi

if ask "Do you want to update macOS (it might take time to download and install)?"; then
	sudo -v
  # Start background keep-alive passing the script PID so the background job
  # can detect when the main script exits and terminate itself.
  _keep_sudo $$ & SUDO_PID=$!
  trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT
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
BREW_PKG_DIR="$SCRIPT_DIR/brew"
IS_BREW_EXECUTED=false
if command -v brew >/dev/null 2>&1; then
	info "brew's housekeeping"
	run brew update
	run brew cleanup
	run brew doctor

  if [[ -f "$BREW_PKG_DIR/Brewfile" ]] && command -v brew >/dev/null 2>&1; then
  	if ask "Do you want to install packages from the Brewfile?"; then
			info "Installing packages from $BREW_PKG_DIR/Brewfile..."
			run brew bundle --file="$BREW_PKG_DIR/Brewfile" --verbose
			ok "Brewfile installation complete"
			IS_BREW_EXECUTED=true
    else
			info "Skipping AppStore installation"
		fi
  fi

  if [[ -f "$BREW_PKG_DIR/AppStore" ]] && command -v brew >/dev/null 2>&1; then
    if ask "Do you want to install packages from the AppStore?"; then
      info "Installing packages from $BREW_PKG_DIR/AppStore..."
      run brew bundle --file="$BREW_PKG_DIR/AppStore" --verbose
      ok "AppStore installation complete"
    else
      info "Skipping AppStore installation"
    fi
  fi
fi

if command -v brew >/dev/null 2>&1 && $IS_BREW_EXECUTED && [[ -f "$BREW_PKG_DIR/Brewfile" ]]; then
  info "Verifying Brewfile..."
  run brew bundle check --file="$BREW_PKG_DIR/Brewfile" || warn "Some packages are still not installed. Re-run after fixing prerequisites."
fi


# OMZ unattended installation
ZSH_HOME="$HOME/.oh-my-zsh"
if [[ ! -d "$ZSH_HOME" ]]; then
	if ask "Do you want to install Oh My Zsh?"; then
		info "Oh My Zsh not found, installing..."

		# .zshrc is managed by stow
		if [[ -e "$HOME/.zshrc" ]]; then
			if [[ -L "$HOME/.zshrc" ]]; then
				# shellcheck disable=SC2088
				warn "You have ~/.zshrc as a symlink. It's being removed due to OMZ installation."
				run rm -- "$HOME/.zshrc"
				info "Configure your ~/.zshrc file"
      else
				if [[ -e "$HOME/.zshrc.bak" ]]; then
					ts="$(date +"%Y%m%d-%H%M%S")"
					# shellcheck disable=SC2088
					info "~/.zshrc.bak already exists; creating timestamped backup ~/.zshrc.bak.$ts"
					run mv -- "$HOME/.zshrc" "$HOME/.zshrc.bak.$ts"
				else
					info "Backing up ~/.zshrc to ~/.zshrc.bak"
					run mv -- "$HOME/.zshrc" "$HOME/.zshrc.bak"
				fi
			fi
    fi

		run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

		# Installing OMZ Plugins
		run git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_HOME/plugins/zsh-syntax-highlighting"
		run git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_HOME/plugins/zsh-autosuggestions"

		# .zshrc is managed by stow
		if [[ -e "$HOME/.zshrc" ]]; then
      if [[ -e "$HOME/.zshrc.bak" ]]; then
        ts="$(date +"%Y%m%d-%H%M%S")"
        # shellcheck disable=SC2088
        info "~/.zshrc.bak already exists; creating timestamped backup ~/.zshrc.bak.$ts"
        run mv -- "$HOME/.zshrc" "$HOME/.zshrc.bak.$ts"
      else
        info "Backing up ~/.zshrc to ~/.zshrc.bak"
        run mv -- "$HOME/.zshrc" "$HOME/.zshrc.bak"
      fi
    fi
	else
		warn "Skipping Oh My Zsh installation"
	fi
fi

if ask "Do you want to apply macOS System Preferences?"; then
	info "Setting macOS System Preferences"
	run bash "${SCRIPT_DIR}/macos.sh"
else
	warn "Skipping macOS System Preferences. You can apply them later via 'macos.sh' script."
fi

if [[ ! -d "$HOME/.sdkman" ]]; then
	if ask "Do you want to install SDKMAN?"; then
		info "Installing SDKMAN..."
		curl -s "https://get.sdkman.io" | bash
	else
		warn "Skipping SDKMAN installation"
	fi
fi

if ask "Do you want to setup .dotfiles?"; then
	source "${SCRIPT_DIR}/dotfiles.sh"
	dotfiles
else
	warn "Skipping .dotfiles setup. You can complete this part later."
fi

finish
exit 0
