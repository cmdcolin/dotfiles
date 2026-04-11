# Dotfiles

## Structure

- `zsh/.zshrc` — common shell config for all machines
- `tmux/.tmux.conf` — common tmux config for all machines
- `hosts/<mac|ubuntu|labserver>/` — machine-specific overrides; use `.zshrc.local` and `.tmux.conf.local` (link.sh skips the non-local versions)
- `zsh/.zpreztorc` — zprezto config (modules, theme, key bindings)

## Adding aliases or functions

- Cross-platform → `zsh/.zshrc`
- macOS-only → `hosts/mac/.zshrc.local`
- Linux (ubuntu) → `hosts/ubuntu/.zshrc.local`
- Labserver → `hosts/labserver/.zshrc.local` — keep minimal; labserver is a shared machine so avoid apt, brew, cargo installs, and anything requiring xclip or a display

## Deploying Configs (Symlinking)

To "activate" these dotfiles, use `link.sh`. This creates symbolic links from this repository to your home directory (`$HOME`), allowing you to edit files here and have the changes take effect immediately.

```sh
./link.sh [mac|ubuntu|labserver]
```

- **Idempotent**: Safe to run multiple times.
- **Backups**: Existing real files in your `$HOME` are moved to `.bak` before the link is created.
- **Host Overrides**: Applies machine-specific overrides from `hosts/` after common configs.

## Installation

```sh
./install.sh [mac|ubuntu|linux]
```

- Installs basic dev tools (brew, apt, cargo, fnm, uv, etc.)
- Sets up Zsh Prezto
- Runs `link.sh` automatically

## Formatting

```sh
./format_shell.sh
```

- Formats all shell and zsh files in the repo using `shfmt` (2-space indent).
