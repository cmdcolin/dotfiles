# Skip non-interactive shells (scp, rsync) to avoid spawning tmux.
[[ $- != *i* ]] && return

[[ -z "$TMUX" ]] && exec tmux

[[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]] && source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

export EDITOR="nvim"

alias e="nvim"
alias vim="nvim"
alias zz="source ~/.zshrc"
alias rmf="rm -rf"
alias claude="claude --dangerously-skip-permissions"

alias mkenv="python -m venv .venv && source .venv/bin/activate"
alias aenv="source .venv/bin/activate"

alias y="pnpm"
alias g="git status"
alias yy="pnpm lint --cache"
alias yyy="pnpm lint --cache --fix"
alias ttt="pnpm typecheck --noEmit --watch"
alias fff="yy --fix && ff"
# Stage everything and amend — "oops, forgot a file".
alias gggg="git add . && git commit --amend --no-edit"
alias mm='git reset --hard origin/main'
# Prepends [skip ci] to last commit to prevent CI on push.
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
# Branches sorted by most recently committed.
alias bb="git branch --sort=-committerdate | fzf | xargs git checkout"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v xclip &>/dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  fi

  function plaintxt() { pandoc -i "$1" -t plain --wrap none | pbcopy; }
  function md() { pandoc "$1" >/tmp/$(basename "$1").html && xdg-open /tmp/$(basename "$1").html; }
  function pandoc_fzf() {
    local file=$(find . -maxdepth 2 -type f | fzf)
    [[ -n "$file" ]] && plaintxt "$file" && echo "✓ Copied '$file' as plain text"
  }

  function chromeclip() { pbpaste | sed 's/^[^:]*:[0-9]* //' | pbcopy; }
  function fireclip() { pbpaste | sed '/^home\//d; /^\[webpack-dev-server\]/d; /^\[HMR\]/d; /^Download the React DevTools/d; /^https:\/\/react.dev/d; s/ home\/[^ ]*:[0-9]\+:[0-9]\+$//' | pbcopy; }

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
alias pserver='miniserve'
alias clean_all="fd -H -t d '^(node_modules|\.next|dist|target)$' -X rm -rf"

# Pitch-down/slow-down audio and video.
vaporwave() { ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "${1%.*}.vwave${2:-0.66}.${1##*.}"; }
vvid() { ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/${2:-0.66}*PTS[v];[0:a]asetrate=44100*${2:-0.66},aresample=44100[a]" -map "[v]" -map "[a]" "${1%.*}.vwave${2:-0.66}.${1##*.}"; }
vpv() { mpv --speed="${2:-0.66}" --audio-pitch-correction=no "$1"; }
vp() { yt-dlp -f 'bestaudio[ext=m4a]' -o - "$1" | ffplay -hide_banner -loglevel error -i pipe:0 -af "asetrate=44100*${2:-0.66},aresample=44100"; }

# Keep failed commands in history.
zshaddhistory() { return 0; }

export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
[[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"

# Version managers and integrations
export PATH="$PATH:$HOME/.local/bin"

command -v fnm &>/dev/null && eval "$(fnm env)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
fi

[ -f ~/.env ] && source ~/.env

function upall() {
  if command -v rustup &>/dev/null; then
    rustup update && cargo install-update -a
  fi
  if [[ -d ~/.fzf/.git ]]; then
    (cd ~/.fzf && git pull) && ~/.fzf/install --all
  fi
  command -v uv &>/dev/null && uv self update
  command -v yt-dlp &>/dev/null && yt-dlp -U
  nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew update && brew upgrade && brew cleanup
  elif command -v apt &>/dev/null; then
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
  fi
}

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
