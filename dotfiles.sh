#!/usr/bin/env bash

dotfiles() {
	local repo_url="https://github.com/aaukhatov/macbook-setup.git"
  local repo_name

  if ! command -v git >/dev/null 2>&1; then
		warn "git is not installed"
		return 1
	fi

  repo_name=$(basename -s .git "$repo_url")

	local target_dotfiles_dir
	read -r -p "Provide an absolute path where you want to clone: " target_dotfiles_dir

	if [[ ! -d "$target_dotfiles_dir" ]]; then
    mkdir -p "$target_dotfiles_dir"
  fi

  clone_dir="${target_dotfiles_dir}/${repo_name}"

	run git clone "$repo_url" "${clone_dir}"

	info "Run 'stow' manually to apply .dotfiles from $clone_dir/dotfiles"
}
