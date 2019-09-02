[[ -z "$TMUX" ]] && exec tmux -2
[[ $- != *i* ]] && return

export TERM="xterm-256color"
# export ZSH="/home/cdiesh/.oh-my-zsh"

# ZSH_THEME="avit"
# source $ZSH/oh-my-zsh.sh


export EDITOR="vim"
alias stp="git subtree push --prefix dist origin gh-pages"
alias ll="ls -l"
alias e="vim"
alias g="git status -uno"
alias y="yarn"
alias w="curl wttr.in"
alias tk="tmux kill-server"
alias ag="rg"
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
alias pserver='python -m RangeHTTPServer'
alias smaller="parallel convert -resize 50% {} resized.{} ::: *.jpg"




export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

PATH="/home/cdiesh/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/cdiesh/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/cdiesh/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/cdiesh/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/cdiesh/perl5"; export PERL_MM_OPT;


export PATH=$PATH:~/go/bin:~/bin
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

unsetopt LIST_BEEP
export PATH=$PATH:~/.local/bin
