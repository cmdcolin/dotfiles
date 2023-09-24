[[ -z "$TMUX" ]] && exec tmux -2
[[ $- != *i* ]] && return

#https://github.com/zimfw/git#settings
zstyle ':zim:git' aliases-prefix 'g'
bindkey -v
WORDCHARS=${WORDCHARS//[\/]}
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

export TSC_WATCHFILE=UseFsEventsWithFallbackDynamicPolling
export DEBUG_PRINT_LIMIT=0


function md() {
  pandoc $1 > /tmp/$1.html
  xdg-open /tmp/$1.html
}

export EDITOR="vim"
alias ll="ls -l"
alias e="vim"
alias y="yarn"
alias p="z"
alias r="npm run"
alias rr="npm run dev"
alias v="nvim"
alias g="git status"
alias oo="npm run dev"
alias gd="git diff"
alias ss="yarn start"
alias ag="rg"
alias fd="fdfind"
alias gg="git grep"
alias ggg="git commit --amend --no-edit"
alias gggg="git add . && git commit --amend --no-edit"
alias ggggg="git add . && git commit --amend --no-edit && git push -f"
alias vim="nvim"
alias gp="git add -p"
alias comppng="pngquant *.png; mkdir pngquant; mv *fs8* pngquant; rm *.png;"
alias mm="git checkout main"
alias ppp="git push"
alias ee="cargo run"
alias qq="exit"
alias 00="exit"
alias hh="htop"
alias bb="git branch --sort=-committerdate| fzy |xargs git checkout "
alias bbb="git ls-files| fzy |xargs nvim "
alias bbbb="fd| fzy |xargs nvim "
alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""
alias yy="yarn lint --cache"
alias ff="yarn format --cache"
alias ttt="yarn tsc --noEmit --watch"
alias stp="git subtree push --prefix build origin gh-pages"
alias sau="sudo apt update && sudo apt upgrade"
alias ccc="yarn test --maxWorkers=25%"
alias ydl="youtube-dl"
alias yda="youtube-dl -f 'bestaudio[ext=m4a]' "
alias open="xdg-open"
alias unarx="parallel unar {} ::: *.7z *.rar *.zip"
alias delarx="rm -rf *.zip *.7z *.rar"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias pserver='npx serve'
alias smaller="parallel convert -resize 50% {} resized.{} ::: *.png"
alias cpuspeed="glances --enable-plugin sensors"
alias gitbranch="git log --oneline --graph --all --no-decorate"
alias uprust="rustup update"
alias uprustdeps="cargo install-update -a"
alias upytdl="wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux && chmod +x yt-dlp_linux && mv yt-dlp_linux ~/.local/bin/youtube-dl"
alias upneovim="wget https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage && chmod +x nvim.appimage && mv nvim.appimage ~/.local/bin/nvim"
alias clean_node_modules="find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +"
alias upall="upytdl; upneovim; uprust; uprustdeps; sau"


function vaporwave() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "`basename $1 .m4a`.vaporwave${2:-0.66}.m4a"
}


function sortgff() {
  grep "^#" $1;
  grep -v "^#" $1 | sort -t"`printf '\t'`" -k1,1 -k4,4n;
}


CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

# fnm
eval "`fnm env`"


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH=$PATH:~/.local/bin/

