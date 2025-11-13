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

Run following command in your terminal to start installation

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aaukhatov/macbook-setup/HEAD/install.sh)"
```

> **Tip:** Review the script before running - `install.sh`￼ is short and readable.

### If the repo is already cloned

```shell
chmod +x ./boostrap.sh && ./boostrap.sh
```

## What the bootstrap does

`bootstrap.sh` runs in a series of interactive stages. Each optional step asks for confirmation, and you can safely
re-run the script anytime.

### Stages overview

1. **System preparation**
   Installs **Rosetta** _(on Apple Silicon)_, **Xcode Command Line Tools**, and performs basic macOS readiness checks.

1. **Homebrew setup**
   Installs or updates Homebrew and can apply package lists from the `Brewfile` and `AppStore` bundles.

1. **macOS updates**
   Performs macOS system updates.

1. **macOS preferences**
   Applies your predefined macOS system settings. Individual modules in `macos.d/` can be run separately.

1. **Developer tools**
   Optionally installs **SDKMAN!**

1. **Shell environment**
   Offers installation of **Oh My Zsh** and safely manages existing shell config. It restores an existing `.zshrc` file
   if it was a symlink after installation.

1. **Dotfiles**
   Clones this repo and uses `stow` to link your dotfiles into the home directory.

## .dotfiles

Dotfiles are organized as `stow` packages.
Each folder under `dotfiles/ (e.g., zsh, git, vim)` contains the files that will be symlinked into `$HOME`.

> `stow` commands must be run in the dotfiles directory

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
stow -t "$HOME" -D git
```

### restow (refresh links after moving files within a package)

```shell
stow -t "$HOME" -R vim
```
