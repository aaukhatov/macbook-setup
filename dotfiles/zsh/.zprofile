eval "$(/opt/homebrew/bin/brew shellenv)"

# OrbStack: command-line tools and integration
if [[ -r "${HOME}/.orbstack/shell/init.zsh" ]]; then
  source "${HOME}/.orbstack/shell/init.zsh"
fi
