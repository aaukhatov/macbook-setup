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

	info "Dotfiles cloned to ${clone_dir}/dotfiles"
	info "Next steps to activate them:"
  info "  	cd ${clone_dir}/dotfiles"
  info "  	stow -v -t \"\$HOME\" zsh git vim config"
}
