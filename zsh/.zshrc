# Must come before the tmux exec: skips this file for non-interactive shells
# (scripts, scp, rsync over SSH) so they don't accidentally spawn tmux.
[[ $- != *i* ]] && return

# Automatically spawn tmux for interactive shells.
[[ -z "$TMUX" ]] && exec tmux

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export EDITOR="nvim"

alias e="nvim"
alias zz="source ~/.zshrc"
alias rmf="rm -rf"

# Skips the per-tool-call permissions prompt.
alias claude="claude --dangerously-skip-permissions"

alias mkenv="python -m venv .venv; source .venv/bin/activate"
alias aenv="source .venv/bin/activate"

alias y="pnpm"
alias g="git status"
alias yy="pnpm lint --cache"
alias yyy="pnpm lint --cache --fix"
alias ttt="pnpm exec tsc --noEmit --watch"
alias fff="yy --fix && ff"

# Stage everything and amend last commit — useful for "oops, forgot a file".
alias gggg="git add . && git commit --amend --no-edit"

# Hard-reset to origin/main with a confirmation prompt.
alias mm='read -p "🔥 Reset to origin/main? (y/n) " -n1; echo; [[ $REPLY =~ ^[Yy]$ ]] && git reset --hard origin/main || echo "Cancelled"'

# Amends last commit to prepend [skip ci], preventing a CI run on push.
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'

# Sorted by most recently committed so fresh branches float to the top.
alias bb="git branch --sort=-committerdate| fzf |xargs git checkout "

# Linux-specific helpers (Shared across Ubuntu/Labserver)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Clipboard workaround if xclip is available
  if command -v xclip &>/dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  fi

  # Pandoc helpers
  function plaintxt() { pandoc -i "$1" -t plain --wrap none | pbcopy; }
  function md() { pandoc "$1" >/tmp/$(basename "$1").html && xdg-open /tmp/$(basename "$1").html; }
  function pandoc_fzf() {
    local file=$(find . -maxdepth 2 -type f | fzf)
    [[ -n "$file" ]] && plaintxt "$file" && echo "✓ Copied '$file' as plain text"
  }

  # Browser log cleaning helpers
  function chromeclip() { pbpaste | sed 's/^[^:]*:[0-9]* //' | pbcopy; }
  function fireclip() { pbpaste | sed '/^home\//d; /^\[webpack-dev-server\]/d; /^\[HMR\]/d; /^Download the React DevTools/d; /^https:\/\/react.dev/d; s/ home\/[^ ]*:[0-9]\+:[0-9]\+$//' | pbcopy; }
  function firefile() { sed '/^home\//d; /^\[webpack-dev-server\]/d; /^\[HMR\]/d; /^Download the React DevTools/d; /^https:\/\/react.dev/d; s/ home\/[^ ]*:[0-9]\+:[0-9]\+$//' "$1" | pbcopy; }

  alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""

  # Brew on Linux
  [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

alias hh="htop"
alias qq="exit"
alias ee="cargo run"
alias ss="pnpm start"
alias rr="pnpm run dev"
alias p="z"
alias ff="pnpm format --cache"
alias pserver='npx serve'

# Vaporwave: Pitch-down and slow-down audio/video.
vwave() { ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "${1%.*}.vwave${2:-0.66}.${1##*.}"; }
vvid() { ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/${2:-0.66}*PTS[v];[0:a]asetrate=44100*${2:-0.66},aresample=44100[a]" -map "[v]" -map "[a]" "${1%.*}.vwave${2:-0.66}.${1##*.}"; }
vpv() { mpv --speed="${2:-0.66}" --audio-pitch-correction=no "$1"; }
vp() { yt-dlp -f 'bestaudio[ext=m4a]' -o - "$1" | ffplay -hide_banner -loglevel error -i pipe:0 -af "asetrate=44100*${2:-0.66},aresample=44100"; }

alias clean_all="fd -H -t d '^(node_modules|\.next|dist|target)$' -X rm -rf"

# By default zsh drops commands that exit non-zero from history.
zshaddhistory() { return 0; }

# Sparse protocol fetches only the index entries you actually need, much
# faster than the legacy git-based full-clone approach.
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

# Node / PNPM
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
[[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"

# Version managers and integrations
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Android
if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
fi
export PATH=$PATH:~/.local/bin/

[ -f ~/.env ] && source ~/.env

# Update all tools
function upall() {
  echo "Updating Rust & Cargo..."
  rustup update && cargo install-update -a

  if [[ -d ~/.fzf/.git ]]; then
    echo "Updating fzf..."
    (cd ~/.fzf && git pull) && ~/.fzf/install --all
  fi

  echo "Updating CLI tools (uv, yt-dlp)..."
  command -v uv &>/dev/null && uv self update
  command -v yt-dlp &>/dev/null && yt-dlp -U

  echo "Updating Neovim plugins..."
  nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Updating Homebrew..."
    brew update && brew upgrade && brew cleanup
  elif command -v apt &>/dev/null && sudo -n true 2>/dev/null; then
    echo "Updating apt..."
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
  fi

  echo "✅ All updates complete!"
}

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

# Machine-specific overrides sourced last so they can override anything above.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
