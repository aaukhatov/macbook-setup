# Arturito's MacBook Setup 🐒

Automates a full macOS developer setup — installing essential CLI tools, Homebrew packages, and linking personalized
dotfiles via GNU Stow. Keeps your macOS environment consistent across machines.

## Installation

Run following command in your terminal

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aaukhatov/macbook-setup/HEAD/install.sh)"
```

> **Tip:** Review the script before running — install.sh￼ is short and readable.

## .dotfiles

Dotfiles are organized as `stow` packages.
Each folder under `dotfiles/ (e.g., zsh, git, vim)` contains the files that will be symlinked into `$HOME`.

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
