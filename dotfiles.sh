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
	if ask "Do you want to activate .dotfiles?"; then
		activate_dotfiles "${clone_dir}/dotfiles"
	else
		info "${GREEN}${BOLD}Next steps to activate them:${RESET}"
		info "  	${GREEN}${BOLD}cd ${clone_dir}/dotfiles${RESET}"
		info "  	${GREEN}${BOLD}stow -v -t \"\$HOME\" zsh git vim config${RESET}"
	fi
}

activate_dotfiles() {
	local dotfiles_dir="${1:-}"
  cd "$dotfiles_dir" || {
    err "Cannot cd into $dotfiles_dir"
    exit 1
  }

  # Collect only directories (packages)
  packages=()
  for d in */; do
    [ -d "$d" ] || continue
    packages+=("${d%/}")
  done

  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No packages found in $dotfiles_dir."
    return 0
  fi

  info "Activating dotfiles from $dotfiles_dir → $HOME"
  local is_stowed=false
  for pkg in "${packages[@]}"; do
    if ask "	↳ stowing package: $pkg"; then
			stow -v -t "$HOME" "$pkg"
			is_stowed=true
		else
			warn "Skipping package: $pkg"
		fi
  done

	if $is_stowed; then
  	ok "Dotfiles are stowed successfully."
  fi
}
