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
	read -r -p "Enter the path to clone the dotfiles repository (existing directory will be replaced): " target_dotfiles_dir

	if [[ ! -d "$target_dotfiles_dir" ]]; then
    mkdir -p "$target_dotfiles_dir"
  fi

  clone_dir="${target_dotfiles_dir}/${repo_name}"

	run git clone "$repo_url" "${clone_dir}"

	ok "Dotfiles cloned to ${clone_dir}/dotfiles"
	info "${GREEN}${BOLD}Next steps to activate them:${RESET}"
  info "  	${GREEN}${BOLD}cd ${clone_dir}/dotfiles${RESET}"
  info "  	${GREEN}${BOLD}stow -v -t \"\$HOME\" zsh git vim config${RESET}"
}

activate_dotfiles() {
	local dotfiles_dir="${1:-}"
  cd "$dotfiles_dir" || {
    err "Cannot cd into $dotfiles_dir"
    exit 1
  }

  # Collect only directories (packages)
  local packages=()
  mapfile -t packages < <(find . -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No packages found in $dotfiles_dir."
    return 0
  fi

  info "Activating dotfiles from $dotfiles_dir → $HOME"
  for pkg in "${packages[@]}"; do
    echo "   ↳ stowing package: $pkg"
    stow -v -t "$HOME" "$pkg"
  done

  ok "Dotfiles activated successfully."
}
