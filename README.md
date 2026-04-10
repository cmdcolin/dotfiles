# my dotfiles

A list of my dotfiles

Includes

- tmux
- zsh
- neovim (not in this repo, I use a fork of kickstart.nvim maintained here
  https://github.com/cmdcolin/mysetup.nvim)

## Installation

```bash
./install.sh      # Install tools and dependencies
./link.sh mac     # Link with macOS-specific configs
./link.sh ubuntu  # Link with Ubuntu-specific configs
```

### Usage

Use `./link.sh --help` to see all available options:

```bash
./link.sh --help        # Show help
./link.sh mac           # Link with macOS configs (primary secondary)
./link.sh ubuntu        # Link with Ubuntu configs (primary primary)
./link.sh labserver     # Link with labserver configs
./link.sh               # Link common configs only (no OS-specific overrides)
```

The script applies host-specific overrides after linking common configs, so OS-specific settings like package managers, clipboard tools, and paths are correctly configured per machine.

## Modular Dotfile Structure

Dotfiles are organized into "packages" (folders). Each folder is mirrored to
your `$HOME` directory.

- `git/`: contains `.gitconfig`
- `zsh/`: contains `.zshrc`, `.zimrc`
- `pnpm/`: contains `.config/pnpm/rc`
- `hosts/$(hostname)/`: contains host-specific overrides

To add a new config, just create a new directory and put the files in it,
mirroring the structure you want in your home directory.

## Details about my setup

- Computer - Dell laptop with 32gb RAM, 512GB SSD (primary) / MacBook Pro (secondary)
- OS - Ubuntu 24.10 (primary) / macOS (secondary)
- Music player - [fml9000](https://github.com/cmdcolin/fml9000) or
  [ytshuffle](https://cmdcolin.github.io/ytshuffle/)
- Text editor - neovim, kickstart.nvim setup
- Browser - Firefox
- Browser Add-ons - Dark Reader, uBlock origin

## Music player setup

I started creating my own music player to try to bring my foobar2000 to native
linux with gtk4-rs

![](https://github.com/cmdcolin/fml9000/raw/master/img/1.png)

Progress is slow on it but it does play MP3s :)
<https://github.com/cmdcolin/fml9000>

I also made an app, ytshuffle, to load entire channels worth of youtubes and
browse like a music library. See <https://cmdcolin.github.io/ytshuffle/>

## Old stuff

[Older setup stuff](./OLD)

## References

<https://github.com/manzt/dotfiles>

## Note

I have gotten repetitive strain injury in the past, and some of my weird config
is trying to help with that, for example there are many 'double tap' key
commands which kinda help me from contorting my hand. See
<https://cmdcolin.github.io/posts/2022-07-08-pinky>
