# Customize to your needs...
[[ -z "$TMUX" ]] && exec tmux -2
[[ $- != *i* ]] && return



#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export EDITOR="nvim"
alias e="nvim"
alias python="python3"
alias vm="nvim"
alias y="yarn"
alias p="z"
alias pp="python"
alias r="npm run"
alias lg="lazygit"
alias gti="git"
alias rr="npm run dev"
alias mm="git reset --hard origin/main"
alias rrr="npm run dev --open"
alias v="nvim"
alias yl="yarn upgrade-interactive --latest"
alias g="git status"
alias oo="npm run dev"
alias gd="git diff"
alias ss="yarn start"
alias fd="fdfind"
alias bn="y build:esm --watch  --preserveWatchOutput"
alias gg="git grep"
alias gm="git commit -m"
alias ggg="git commit --amend --no-edit"
alias gggg="git add . && git commit --amend --no-edit"
alias ggggg="git add . && git commit --amend --no-edit && git push -f"
alias vim="nvim"
alias gp="git add -p"
alias comppng="pngquant *.png; mkdir pngquant; mv *fs8* pngquant; rm *.png;"
alias gc="git checkout"
alias ee="cargo run"
alias eee="PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/ cargo run"
alias qq="exit"
alias 00="exit"
alias hh="htop"
alias bb="git branch --sort=-committerdate| fzy |xargs git checkout "
alias bbb="git ls-files| fzy |xargs nvim "
alias bbbb="fd| fzy |xargs nvim "
alias zz="cd \$(fd . '/home/cdiesh' | fzy)"
alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""
alias upfzf="cd ~/.fzf; git pull; cd -; ~/.fzf/install --all"
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
alias clean_node_modules="find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +"
alias clean_next="find . -name '.next' -type d -prune -exec rm -rf '{}' +"
alias clean_dist="find . -name 'dist' -type d -prune -exec rm -rf '{}' +"
alias clean_target="find . -name 'target' -type d -prune -exec rm -rf '{}' +"
alias upall="brew upgrade; uprust; uprustdeps; sau;  upfzf"


function vaporwave() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "`basename $1 .m4a`.vaporwave${2:-0.66}.m4a"
}


function vaporwavemp3() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "`basename $1 .mp3`.vaporwave${2:-0.66}.mp3"
}

function vaporvideo() {
  ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/${2:-0.66}*PTS[v];[0:a]asetrate=44100*${2:-0.66},aresample=44100[a]" -map "[v]" -map "[a]" "`basename $1 .mp4`.vaporwave${2:-0.66}.mp4"
}

function vaporwaveogg() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "`basename $1 .ogg`.vaporwave${2:-0.66}.ogg"
}


function sortgff() {
  grep "^#" $1;
  grep -v "^#" $1 | sort -t"`printf '\t'`" -k1,1 -k4,4n;
}

function rg2() {
  rg --pretty $1 |
    perl -0 -pe 's/\n\n/\n\0/gm' |
    fzf --read0 --ansi --multi --highlight-line --layout reverse |
    perl -ne '/^([0-9]+:|$)/ or print' | xargs nvim 
}


function md() {
  pandoc $1 > /tmp/$1.html
  xdg-open /tmp/$1.html
}

function file_ends_with_newline() {
  [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}

export TSC_WATCHFILE=UseFsEventsWithFallbackDynamicPolling
export DEBUG_PRINT_LIMIT=0
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

eval "`fnm env`"


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH=$PATH:~/.local/bin/



eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
source /etc/profile.d/sra-tools.sh
source ~/.env
