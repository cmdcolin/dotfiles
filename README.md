# my dotfiles

tmux, zsh, git, etc. Neovim config is separate: https://github.com/cmdcolin/mysetup.nvim

## install

```bash
./install.sh         # Auto-detects OS
./install.sh mac     # macOS
./install.sh ubuntu  # Ubuntu/Linux
```

Or just link configs without installing packages:

```bash
./link.sh
```

## tmux

Prefix is `C-]`. Splits:

- `C-]` `=` — split side-by-side
- `C-]` `-` — split stacked

### nested tmux (e.g. ssh'd into a server)

The local tmux eats the prefix first, so hit it twice to pass it through to the
remote session (`bind C-] send-prefix`):

- `C-]` `C-]` `=` — split the remote tmux side-by-side
- `C-]` `C-]` `-` — split the remote tmux stacked

### clipboard

Copying (drag-select, `y`, or `Enter` in copy mode) always targets the clipboard
of the machine you're *sitting at*, including from a tmux on a remote box:
alongside `pbcopy`/`xclip`, tmux emits an OSC 52 escape sequence that the local
terminal turns into a clipboard write. No X11 forwarding needed. This relies on
`set -g set-clipboard on` — the default `external` makes a local tmux swallow a
nested remote tmux's sequence instead of relaying it.

Requires a terminal with OSC 52 enabled (iTerm2, WezTerm, Ghostty, kitty,
Alacritty, foot; iTerm2 needs *Allow clipboard access to terminal apps*). Apple
Terminal.app does not support it.

Pasting is just the terminal's own paste (`Cmd-V` / `Ctrl-Shift-V`) — it types
the local clipboard into the remote shell. Terminals can't be read back over
OSC 52, so there's no way to pull the local clipboard into a remote `pbpaste`.

## setup

- Machine: Dell laptop 32gb/512GB (primary), MacBook Pro (secondary)
- OS: Ubuntu 24.10 / macOS
- Editor: neovim (kickstart.nvim)
- Browser: Firefox + Dark Reader + uBlock
- Music: [fml9000](https://github.com/cmdcolin/fml9000) or [ytshuffle](https://cmdcolin.github.io/ytshuffle/)

Some keybindings are set up to avoid RSI — lots of double-tap commands to avoid hand contortion. More here: https://cmdcolin.github.io/posts/2022-07-08-pinky

[older stuff](./OLD)
