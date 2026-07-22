# Dotfiles

## Structure

- `zsh/.zshrc` — shell config; OS-specific bits live inside `if [[ "$OSTYPE" == "linux-gnu"* ]]` / `darwin` blocks
- `zsh/.zpreztorc` — zprezto config
- `tmux/.tmux.conf` — tmux config; branch on OS with `if-shell 'uname -s | grep -q Darwin'`, never `%if "#{==:#(uname -s),Darwin}"` — `#()` evaluates to empty during config parsing, so that form silently takes the else branch

Labserver is a shared machine — avoid apt/brew/cargo installs and anything requiring xclip or a display when adding to `.zshrc`.

## Deploying Configs (Symlinking)

To "activate" these dotfiles, use `link.sh`. This creates symbolic links from this repository to your home directory (`$HOME`), allowing you to edit files here and have the changes take effect immediately.

```sh
./link.sh
```

Every file under each top-level dir (except `img/` and `OLD/`) is mirrored into
`$HOME` at the same relative path — so `zsh/.zshrc` becomes `~/.zshrc` and
`claude/.claude/CLAUDE.md` becomes `~/.claude/CLAUDE.md`.

- **Idempotent**: Safe to run multiple times. Takes no arguments — there are no
  per-host config variants.
- **Backups**: Existing real files in `$HOME` are moved to `.bak` first.
- **Cleanup**: Dangling `$HOME` symlinks pointing into this repo are removed.
- Per-machine settings that shouldn't be committed go in `~/.zshrc.local`, which
  `.zshrc` sources if present.

## Installation

```sh
./install.sh [mac|ubuntu|labserver]
```

- Installs basic dev tools (brew, apt, cargo, fnm, uv, etc.)
- Sets up Zsh Prezto
- Runs `link.sh` automatically

## Git

Always commit with an explicit pathspec (`git commit -- <paths>`), never `git
add` plus a bare `git commit`. Another agent may be working in the same worktree,
and the git index is shared, so a bare commit silently sweeps up whatever they
have staged (and theirs sweeps up yours).

This applies to `--amend` too, where it's worse: the stray files land in a commit
that already exists rather than a new one, so the mistake is behind you before
it's visible.

## Formatting

```sh
find . \( -name "*.sh" -o -name ".zshrc" -o -name ".zshrc.local" -o -name ".zpreztorc" \) | xargs shfmt -w -i 2
```
