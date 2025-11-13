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

info()  { printf '%s\n' "${BLUE}${BOLD}==> $*${RESET}"; }
warn()  { printf '%s\n' "${YELLOW}${BOLD}==>[!] $*${RESET}"; }
err()   { printf '%s\n' "${RED}${BOLD}==>[✗] $*${RESET}" >&2; }
ok()    { printf '%s\n' "${GREEN}${BOLD}==>[✓] $*${RESET}"; }

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

ask() {
  local prompt="$1"
  local answer

  while true; do
    read -r -p "${YELLOW}${BOLD}$prompt [y/N]:${RESET} " answer
    case "$answer" in
      [Yy]*) return 0 ;;  # yes → success
      [Nn]*) return 1 ;;  # no  → failure
      *) err "Please answer y or n." ;;
    esac
  done
}

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
  printf '%s\n' " ${BLUE}────────────────────────────────────────${RESET}"
  printf '%s\n' " ${GREEN}${BOLD} You're ready to rock 🤘 time to build something awesome 🚀 ${RESET}"
  printf '\n'
}
