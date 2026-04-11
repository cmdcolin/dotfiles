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

## Linking

```sh
./link.sh mac|ubuntu|labserver
```

Symlinks all configs to `$HOME`. Idempotent — safe to re-run. Backs up existing real files to `.bak`.

## Install scripts

- `install_mac.sh` — full dev setup via brew + cargo
- `install_linux.sh` — full dev setup via apt + cargo (for ubuntu, not labserver)
- No install script for labserver — set up manually and minimally
