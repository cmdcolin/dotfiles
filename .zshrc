[[ -z "$TMUX" ]] && exec tmux -2
[[ $- != *i* ]] && return

## https://github.com/zimfw/git#settings
zstyle ':zim:git' aliases-prefix 'g'




# Start configuration added by Zim install {{{
#
# User configuration sourced by interactive shells
#

# -----------------
# Zsh configuration
# -----------------


#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------

# Use degit instead of git as the default tool to install and update modules.
#zstyle ':zim:zmodule' use 'degit'

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

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

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#

zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install






export TSC_WATCHFILE=UseFsEventsWithFallbackDynamicPolling
export DEBUG_PRINT_LIMIT=0


function md() {
  pandoc $1 > /tmp/$1.html
  xdg-open /tmp/$1.html 
}

export EDITOR="vim"
alias ll="ls -l"
alias e="vim"
alias w="curl v2.wttr.in"
alias y="yarn"
alias p="z"
alias g="git status"
alias gd="git diff"
alias ss="yarn start"
alias ag="rg"
alias fd="fdfind"
alias tt="yarn typecheck"
alias lg="lazygit"
alias vv="vim"
alias vun="vim"
alias ggg="git commit --amend --no-edit"
alias ee="cargo run"
alias rr="git reset --hard origin/main"
alias qq="exit"
alias bb="git branch --sort=-committerdate| fzf --height=20% |xargs git checkout "
alias gb="git branch --sort=-committerdate"
alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""
alias yy="yarn lint --cache"
alias ff="yarn format --cache"
alias vim="~/.local/bin/nvim"
alias ttt="yarn tsc --noEmit --watch"
alias stp="git subtree push --prefix build origin gh-pages"
alias sau="sudo apt update && sudo apt upgrade"
alias saa="appimageupdate ~/.local/bin/nvim"
alias cov="yarn test --coverage && open coverage/lcov-report/index.html"
alias ydl="youtube-dl"
alias yda="youtube-dl -f 'bestaudio[ext=m4a]' "
alias open="xdg-open"
alias glp="git log -p"
alias unarx="parallel unar {} ::: *.7z *.rar *.zip"
alias delarx="rm -rf *.zip *.7z *.rar"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias pserver='npx serve'
alias smaller="parallel convert -resize 50% {} resized.{} ::: *.png"
alias cpuspeed="glances --enable-plugin sensors"
alias gitbranch="git log --oneline --graph --all --no-decorate"


function vaporwave() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.5},aresample=44100" "`basename $1 .m4a`.vaporwave.m4a"
}



[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH=$PATH:~/.local/bin/

# fnm
export PATH=/home/cdiesh/.fnm:$PATH
eval "`fnm env`"


function sortgff() {
  grep "^#" $1;
  grep -v "^#" $1 | sort -t"`printf '\t'`" -k1,1 -k4,4n;
}


source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
