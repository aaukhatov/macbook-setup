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

run() {
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

# Start background keep-alive passing the script PID so the background job
# can detect when the main script exits and terminate itself.
_keep_sudo $$ & SUDO_PID=$!
trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT

# Show language menu in the top right corner of the boot screen
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Set the timezone; see `sudo systemsetup -listtimezones` for other values
sudo systemsetup -settimezone "Europe/Amsterdam" > /dev/null

# Enable lid wakeup
sudo pmset -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Sleep the display after 15 minutes
sudo pmset -a displaysleep 15

run sudo softwareupdate -i -a

# Install Rosetta only on Apple Silicon (best-effort)
if [[ "$(uname -m)" == "arm64" ]]; then
  if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
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
  printf '%s\n' " ${YELLOW}  • Tip: open a new terminal to load shell changes${RESET}"
  printf '%s\n' " ${BLUE}────────────────────────────────────────${RESET}"
  printf '%s\n' " ${GREEN}${BOLD} You're ready to rock, 🤘 time to build something awesome 🚀 ${RESET}"
  printf '\n'
}

finish
exit 0
