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

# Customize to your needs...
#
#
[[ -z "$TMUX" ]] && exec tmux -2
[[ $- != *i* ]] && return

export EDITOR="vim"
alias ll="ls -l"
alias e="vim"
alias g="git status"
alias w="curl v2.wttr.in"
alias y="yarn"
alias ss="yarn start"
alias ag="rg"
alias fd="fdfind"
alias ff="fd|grep"
alias qq="exit"
alias gb="git branch --sort=-committerdate"
alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""
alias yy="yarn lint --cache"
alias vim="~/.local/bin/nvim"
alias stp="git subtree push --prefix build origin gh-pages"
alias sau="sudo apt update && sudo apt upgrade"
alias cov="yarn test --coverage && open coverage/lcov-report/index.html"
alias ydl="youtube-dl"
alias yda="youtube-dl -f 'bestaudio[ext=m4a]' "
alias open="xdg-open"
alias unarx="parallel unar {} ::: *.7z *.rar *.zip"
alias delarx="rm -rf *.zip *.7z *.rar"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias pserver='python3 -m RangeHTTPServer'
alias smaller="parallel convert -resize 50% {} resized.{} ::: *.png"
alias cpuspeed="glances --enable-plugin sensors"
alias gitbranch="git log --oneline --graph --all --no-decorate"


## cpanm
PATH="/home/cdiesh/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/cdiesh/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/cdiesh/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/cdiesh/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/cdiesh/perl5"; export PERL_MM_OPT;



source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
unsetopt BEEP

function vaporwave() {
  ffmpeg -i "$1" -af "asetrate=44100*0.5,aresample=44100" "`basename $1 .m4a`.vaporwave.m4a"
}



export FZF_DEFAULT_COMMAND='rg --files'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

export PATH=$PATH:/home/linuxbrew/.linuxbrew/opt/python@3.9/libexec/bin

