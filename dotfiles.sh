#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

dotfiles() {
	local target_dotfiles_dir
	repo_url="https://github.com/aaukhatov/macbook-setup.git"
  repo_name=$(basename -s .git "$repo_url")
	read -r -p "Provide an absolute path where you want to clone: " target_dotfiles_dir
	if [[ ! -d "$target_dotfiles_dir" ]]; then
    mkdir -p "$target_dotfiles_dir"
  fi
	run git clone "$repo_url" "${target_dotfiles_dir}/${repo_name}"
	info "Run stow manually to apply .dotfiles"
}
