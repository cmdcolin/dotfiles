[[ -z "$TMUX" ]] && exec tmux -2
[[ $- != *i* ]] && return

export EDITOR="vim"
alias stp="git subtree push --prefix build origin gh-pages"
alias ll="ls -l"
alias e="vim"
alias g="git status -uno"
alias y="yarn"
alias w="curl v2.wttr.in"
alias tk="tmux kill-server"
alias ag="rg"
alias gg="glances --enable-plugin sensors"
alias fd="fdfind"
alias gst="vim '+Gedit :'"
alias vim="nvim"
alias ff="fd|grep"
alias yy="yarn lint --cache"
alias sau="sudo apt update&&sudo apt upgrade"
alias cov="yarn test --coverage && open coverage/lcov-report/index.html"
alias ydl="youtube-dl"
alias yda="youtube-dl -f 'bestaudio[ext=m4a]' "
alias open="xdg-open"
alias grep="grep --color=never"
alias unarx="parallel unar {} ::: ~/Downloads/*.7z(.N) ~/Downloads/*.rar(.N) ~/Downloads/*.zip(.N)"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias pserver='python3 -m RangeHTTPServer'
alias smaller="parallel convert -resize 50% {} resized.{} ::: *.png"


function gitbd() {
  local r="refs"
  [[ $1 ]] && r="$r/remotes/$1" || r="$r/heads"
  while read l; do
    echo ${l}
    echo $'\t' $(git log --date=short -1 --format="%ad %h  %s" ${l})
  done <<< $(git for-each-ref --format='%(refname:short)' --sort=-committerdate ${r})
}


## cpanm
PATH="/home/cdiesh/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/cdiesh/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/cdiesh/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/cdiesh/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/cdiesh/perl5"; export PERL_MM_OPT;



export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"




[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
