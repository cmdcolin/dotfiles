[[ $- != *i* ]] && return

command -v tmux &>/dev/null && [[ -z "$TMUX" ]] && exec tmux

[[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]] && source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

export EDITOR="nvim"
export GPG_TTY=$(tty)

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
alias claude="claude --dangerously-skip-permissions"

alias mkenv="python -m venv .venv && source .venv/bin/activate"
alias aenv="source .venv/bin/activate"

alias y="pnpm"
alias python="python3"
alias g="git status"
alias yy="pnpm lint"
alias yyy="pnpm lint --fix"
alias ttt="pnpm typecheck --noEmit --watch"
alias fff="yyy && ff"
# Stage everything and amend — "oops, forgot a file".
alias gggg="git add . && git commit --amend --no-edit"
alias mm='git reset --hard origin/main'
# Prepends [skip ci] to last commit to prevent CI on push.
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
alias ggl="glances --disable-plugin gpu"
# Branches sorted by most recently committed.
alias bb="git branch --sort=-committerdate | fzf | xargs git checkout"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # prezto's utility module already aliases pbcopy/pbpaste to xclip or xsel,
  # whichever it finds, so we only need to handle the case it can't: no
  # clipboard tool at all (labserver, no X display). `function pbcopy { }`
  # (not `pbcopy() { }`) avoids zsh's "defining function based on alias"
  # parse error when prezto's alias is already in scope, since it's parsed
  # unambiguously as a function definition regardless of any existing alias.
  if command -v xclip &>/dev/null || command -v xsel &>/dev/null; then
    chromeclip() { pbpaste | sed 's/^[^:]*:[0-9]* //' | pbcopy; }
    fireclip() { pbpaste | sed '/^home\//d; /^\[webpack-dev-server\]/d; /^\[HMR\]/d; /^Download the React DevTools/d; /^https:\/\/react.dev/d; s/ home\/[^ ]*:[0-9]\+:[0-9]\+$//' | pbcopy; }
  else
    # No X display (labserver): OSC 52 hands the text to the local terminal.
    function pbcopy { printf '\033]52;c;%s\a' "$(base64 | tr -d '\n')" >/dev/tty; }
  fi

  alias ww="watch -n.1 \"grep '^[c]pu MHz' /proc/cpuinfo\""
  alias sau="sudo apt update && sudo apt upgrade"
  alias eee="PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/ cargo run"

  command -v gpg-connect-agent &>/dev/null && gpg-connect-agent updatestartuptty /bye &>/dev/null

  [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

alias claude2='CLAUDE_CONFIG_DIR=~/.claude2 claude'
alias claude3='CLAUDE_CONFIG_DIR=~/.claude3 claude'
alias ll="ls -l"
alias hh="htop"
alias qq="exit"
alias ee="cargo run"
alias ss="pnpm start"
alias rr="pnpm run dev"
alias p="z"
alias ff="pnpm format"
alias pserver='miniserve .'

# Delete build/dependency dirs under the given paths (cwd if none), after
# showing what will go. A function, not an alias: with an alias the paths land
# after `-X rm -rf` and become arguments to rm, so `clean_all ~/src/foo` would
# delete all of foo. -I because these dirs are gitignored in exactly the repos
# worth cleaning; --prune so a nested node_modules isn't listed under its own
# parent.
clean_all() {
  local -a targets found
  targets=("$@")
  (($#targets)) || targets=(.)

  # Split on NUL, then drop the empty trailing field in a separate step — the
  # nested ${(@)${(0)...}:#} form parses but never applies the :# filter.
  found=("${(0)$(fd -H -I --prune -t d '^(node_modules|\.next|dist|target|\.venv)$' -0 "${targets[@]}")}")
  found=("${(@)found:#}")
  if ! (($#found)); then
    print "clean_all: nothing to remove under ${(j:, :)targets}"
    return 0
  fi

  print -rl -- "$found[@]"
  print -n "clean_all: remove these $#found dir(s), $(du -shc "$found[@]" 2>/dev/null | tail -1 | cut -f1) total? [y/N] "
  local reply
  read -r reply
  [[ "$reply" == [yY]* ]] || { print "clean_all: aborted"; return 1 }
  rm -rf -- "$found[@]"
}

# Pitch-down/slow-down audio and video.
vaporwave() { ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "${1%.*}.vwave${2:-0.66}.${1##*.}"; }
vvid() { ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/${2:-0.66}*PTS[v];[0:a]asetrate=44100*${2:-0.66},aresample=44100[a]" -map "[v]" -map "[a]" "${1%.*}.vwave${2:-0.66}.${1##*.}"; }
vpv() { mpv --speed="${2:-0.66}" --audio-pitch-correction=no "$1"; }
vp() { yt-dlp -f 'bestaudio[ext=m4a]' -o - "$1" | ffplay -hide_banner -loglevel error -i pipe:0 -af "asetrate=44100*${2:-0.66},aresample=44100"; }

# Keep failed commands in history.
zshaddhistory() { return 0; }

# Keep $path unique so re-sourcing (zz) doesn't stack duplicate entries. Dedupe
# keeps the first occurrence, so prepending an existing dir just moves it front.
typeset -U path

path=("$HOME/.local/bin" $path)

FNM_PATH="$HOME/.local/share/fnm"
[[ -d "$FNM_PATH" ]] && path=("$FNM_PATH" $path)
command -v fnm &>/dev/null && eval "$(fnm env --shell zsh)"

# after fnm so the standalone pnpm wins over corepack's shim
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

upall() {
  if command -v rustup &>/dev/null; then
    rustup update && cargo install-update -a --locked
  fi
  if [[ -d ~/.fzf/.git ]]; then
    (cd ~/.fzf && git pull) && ~/.fzf/install --all
  fi
  command -v uv &>/dev/null && uv self update && uv tool upgrade yt-dlp
  nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew update && brew upgrade && brew cleanup
  elif command -v apt &>/dev/null; then
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
  fi
}

# What is eating the disk? Read-only.
bigdirs() {
  du -xh -d1 "${1:-.}" 2>/dev/null | sort -rh | head -"${2:-20}"
}

# Reclaim disk. Safe by default; --tmp and --docker are opt-in and destructive.
# /tmp is tmpfs size=16G mounted usrquota, so filling it surfaces as
# "disk quota exceeded" (EDQUOT), not "no space left" — check it first.
cleanup() {
  local do_tmp=0 do_docker=0 before after name rev
  for a in "$@"; do
    case $a in
      --tmp) do_tmp=1 ;;
      --docker) do_docker=1 ;;
      --all) do_tmp=1; do_docker=1 ;;
      *) print -u2 "usage: cleanup [--tmp] [--docker] [--all]"; return 1 ;;
    esac
  done
  before=$(df -B1 --output=avail / | tail -1)
  df -h / /tmp | grep -v Filesystem

  print "\n== package manager stores =="
  command -v pnpm &>/dev/null && pnpm store prune
  command -v npm &>/dev/null && npm cache clean --force
  command -v yarn &>/dev/null && yarn cache clean
  command -v uv &>/dev/null && uv cache prune
  command -v pip &>/dev/null && pip cache purge
  command -v go &>/dev/null && go clean -cache -modcache

  print "\n== user caches =="
  # R CMD check and puppeteer scratch dirs; these regrow, never worth keeping
  rm -rf ~/.cache/rcheck/*(N) ~/.cache/pptr-tmp/*(N) ~/.cache/thumbnails(N)

  print "\n== system =="
  sudo journalctl --vacuum-size=500M
  sudo apt-get clean
  sudo apt-get autoremove -y
  sudo rm -rf /var/crash/*(N)
  # snap keeps every superseded revision until told otherwise
  sudo snap set system refresh.retain=2
  snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' |
    while read -r name rev; do sudo snap remove "$name" --revision="$rev"; done

  if (( do_tmp )); then
    print "\n== /tmp (entries untouched for 3+ days) =="
    # -mtime is on the top-level entry, so live sessions and sockets are skipped
    find /tmp -xdev -mindepth 1 -maxdepth 1 -mtime +3 \
      ! -name '.X11-unix' ! -name '.ICE-unix' ! -name '.font-unix' \
      ! -name '.XIM-unix' ! -name '.Test-unix' ! -name 'systemd-private-*' \
      ! -name 'snap-private-*' -print -exec rm -rf {} + 2>/dev/null
  fi

  if (( do_docker )) && command -v docker &>/dev/null; then
    print "\n== docker (unused images — these have to be re-pulled) =="
    docker system df
    docker system prune -a -f
  fi

  after=$(df -B1 --output=avail / | tail -1)
  print "\n== freed $(( (after - before) / 1024 / 1024 ))MB on / =="
  df -h / /tmp | grep -v Filesystem
}

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
