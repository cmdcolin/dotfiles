[[ $- != *i* ]] && return

command -v tmux &>/dev/null && [[ -z "$TMUX" ]] && exec tmux

[[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]] && source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

export EDITOR="nvim"
export GPG_TTY=$TTY

# Prompt (zprezto sorin theme) runs git-info on every precmd, which refreshes
# the index and briefly takes .git/index.lock — this races other git processes
# (e.g. Claude Code) running in the same repo. Optional locks off skips that
# stat-refresh lock for read-only ops like status/diff without affecting real
# writes like commit/add.
export GIT_OPTIONAL_LOCKS=0

alias e="nvim"
alias vim="nvim"
alias zz="source ~/.zshrc"
alias rmf="rm -rf"

alias mkenv="python -m venv .venv && source .venv/bin/activate"
alias aenv="source .venv/bin/activate"

alias y="pnpm"
alias dx="claude --verbose --model haiku -p"
alias pur="pnpm upgrade --recursive"
alias purr="pnpm upgrade --interactive --recursive --latest"
alias gm="git commit -m"
alias ga="git add ."
alias python="python3"
alias g="git status"
alias yy="pnpm lint"
alias ppp="make push-docx && git push"
alias gggg="git add . && git commit --amend --no-edit"
alias hh="htop"
alias ttt="pnpm typecheck --noEmit --watch"
alias mm='git reset --hard origin/main'
alias v="vim"
# Prepends [skip ci] to last commit to prevent CI on push.
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
# Branches sorted by most recently committed.
alias bb="git branch --sort=-committerdate | fzf | xargs git checkout"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # prezto's utility module already aliases pbcopy/pbpaste to xclip or xsel,
  # whichever it finds, so we only need to handle the case it can't: no
  # clipboard tool at all (labserver, no X display). `function pbcopy { }`
  # (not `pbcopy() { }`) avoids zsh's "defining function based on alias"
  # parse error when prezto's alias is already in scope, since it's parsed
  # unambiguously as a function definition regardless of any existing alias.
  if ! command -v xclip &>/dev/null && ! command -v xsel &>/dev/null; then
    # No X display (labserver): OSC 52 hands the text to the local terminal.
    function pbcopy { printf '\033]52;c;%s\a' "$(base64 | tr -d '\n')" >/dev/tty; }
  fi

  alias ww="watch -n.1 \"grep '^[c]pu MHz' /proc/cpuinfo\""
  alias sau="sudo apt update && sudo apt upgrade"

  command -v gpg-connect-agent &>/dev/null && gpg-connect-agent updatestartuptty /bye &>/dev/null

  [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

alias claude2='CLAUDE_CONFIG_DIR=~/.claude2 claude'
alias claude3='CLAUDE_CONFIG_DIR=~/.claude3 claude'
alias ll="ls -l"
alias qq="exit"
alias ee="cargo run"
alias ss="pnpm start"
alias rr="pnpm run dev"
alias p="z"
alias ff="pnpm format"
alias pserver='miniserve .'

# Pitch-down/slow-down audio.
vaporwave() {
  local f="${2:-0.66}" sr
  sr=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$1")
  ffmpeg -i "$1" -vf "setpts=PTS/${f},scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p" -af "asetrate=${sr}*${f},aresample=${sr}" \
    -c:v libx264 -c:a aac -movflags +faststart "${1%.*}.vwave${f}.mp4"
}
vp() { yt-dlp -f 'bestaudio[ext=m4a]' -o - "$1" | ffplay -hide_banner -loglevel error -i pipe:0 -af "asetrate=44100*${2:-0.66},aresample=44100"; }
vpv() {
  local f="${2:-0.66}"
  ffmpeg -v error -i "$(yt-dlp -g -f 'bv*[height<=720]' "$1")" -i "$(yt-dlp -g -f ba "$1")" -c copy -f matroska pipe:1 |
    ffplay -hide_banner -loglevel error -i pipe:0 -vf "setpts=PTS/${f}" -af "aresample=48000,asetrate=48000*${f},aresample=48000"
}

# Resize video to percentage of original (default 50%).
res() { local scale="${2:-50}"; ffmpeg -i "$1" -vf "scale=iw*${scale}/100:ih*${scale}/100" "${1%.*}_${scale}.${1##*.}"; }

# Keep failed commands in history.
zshaddhistory() { return 0; }

# Keep $path unique so re-sourcing (zz) doesn't stack duplicate entries. Dedupe
# keeps the first occurrence, so prepending an existing dir just moves it front.
typeset -U path

path=("$HOME/.local/bin" $path)

# pnpm owns the global node: `pnpm runtime set node <major> -g` drops a node
# symlink in $PNPM_HOME/bin. pnpm itself is the standalone binary with node
# bundled, so nothing here needs a node on PATH to bootstrap.
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
path=("$PNPM_HOME/bin" $path)

[[ -d "$HOME/.deno/bin" ]] && path=("$HOME/.deno/bin" $path)
[[ -d "$HOME/.fzf/bin" ]] && path=("$HOME/.fzf/bin" $path)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  # Array form, not export PATH=... — scalar assignment bypasses typeset -U.
  path+=("$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/cmdline-tools/latest/bin")
fi

[[ -f ~/.env ]] && source ~/.env

# What is eating the disk? Read-only.
bigdirs() {
  du -xh -d1 "${1:-.}" 2>/dev/null | sort -rh | head -"${2:-20}"
}

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

