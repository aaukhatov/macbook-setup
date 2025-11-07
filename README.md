# Arturito's MacBook Setup 🐒

## Installation

Run following command in your terminal

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aaukhatov/macbook-setup/HEAD/install.sh)"
```

## .dotfiles

Dotfiles are managed by `stow`. Commands below must be run from dotfiles directory.

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
