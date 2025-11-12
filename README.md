# Arturito's MacBook Setup 🐒

Automates almost full macOS developer setup - installing essential CLI tools, Homebrew packages, and linking
personalized
dotfiles via GNU Stow. Keeps my macOS environment consistent across machines.

```
macbook-setup/
├── bootstrap.sh        		# Main entry script
├── utils.sh            		# Shared functions
├── install.sh          		# Installer script
├── brew/
│   ├── Brewfile        		# Homebrew packages (formulas, casks, taps)
│   ├── AppStore        		# macOS App Store apps managed via `mas`
│   └── VSCodeExtension 		# VS Code extensions managed via `code` CLI
├── dotfiles.sh         		# Helper to clone and link dotfiles using stow
├── dotfiles/           		# Directory with stow-managed configuration packages
│   ├── zsh/            		# .zshrc, .zshenv, .zshprofile
│   ├── git/            		# .gitconfig, .gitignore
│   ├── vim/            		# .vimrc and related files
│   └── config/         		# Misc app configs
├── macos.sh         			# macOS settings
├── macos.d/
│   ├── activity_monitor.sh     # ActiveMonitor preferences
│   ├── dock.sh            		# Dock preferences
│   ├── finder.sh            	# Finder preferences
│   ├── mail.sh            		# Default mail client preferences
│   ├── software_update.sh      # Software Update related settings
│   └── keyboard-bindings.xml   # Keyboard binding customization
└── README.md           		# Project documentation (you are here)
```

## Installation

Run following command in your terminal to install from the scratch

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aaukhatov/macbook-setup/HEAD/install.sh)"
```

> **Tip:** Review the script before running — install.sh￼ is short and readable.

### If the repo is already cloned

```shell
chmod +x ./boostrap.sh && ./boostrap.sh
```

## What the bootstrap does

`bootstrap.sh` runs in a series of interactive stages. Each optional step asks for confirmation, and you can safely
re-run the script anytime.

### Stages & Prompts (in order)

1. **System checks**
	- Ensures macOS, installs Rosetta (Apple Silicon), installs Xcode CLT if missing.

2. **Homebrew setup**
	- Installs/updates Homebrew.
	- Optional prompt: install packages from `brew/Brewfile`.
	- Optional prompt: install Mac App Store apps from `brew/AppStore`.

3. **macOS updates (optional)**
	- Prompt: *Update macOS now?*

4. **Shell environment**
	- Prompt: install Oh My Zsh (backs up existing `.zshrc`).

5. **macOS preferences**
	- Prompt: apply default macOS settings.
	- You can also run individual modules from `macos.d/`.

6. **Developer tools**
	- Prompt: install SDKMAN!.

7. **Dotfiles**
	- Prompt: apply dotfiles via `stow` from the `dotfiles/` directory.

> **Re-running**
> If a step was skipped or something failed (e.g., App Store sign-in), just re-run `./bootstrap.sh`. It will skip
> completed work and re-offer the prompts.

## .dotfiles

Dotfiles are organized as `stow` packages.
Each folder under `dotfiles/ (e.g., zsh, git, vim)` contains the files that will be symlinked into `$HOME`.

> stow commands must be run in the dotfiles directory

### dry run first (highly recommended)

```shell
stow -n -v -t "$HOME" zsh git
```

### stow zsh package only

```shell
stow -v -t "$HOME" zsh
```

### stow multiple packages

```shell
stow -v -t "$HOME" config git vim
```

### unlink a package (remove symlinks only)

```shell
stow --target="$HOME" -D git
```

### restow (refresh links after moving files within a package)

```shell
stow --target="$HOME" -R vim
```
