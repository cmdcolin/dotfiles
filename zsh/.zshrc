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
alias gitt="git tag --sort=committerdate"
alias mkenv="python -m venv .venv; source .venv/bin/activate"
alias ppp="pnpm install"
alias aenv="source .venv/bin/activate"
alias punzip="pigz -d"
alias gnn="git commit --amend --no-edit"
alias gnnn="git commit -a --amend --no-edit"
alias gmm="git commit -m"
alias pzip="pigz"
alias pgzip="bgzip -@8"
alias gemini="gemini --yolo"
alias zz="source ~/.zshrc"
alias e="nvim"
alias python="python3"
alias vm="nvim"
alias t="pnpm install"
alias rmf="rm -f"
alias gemmy="npx https://github.com/google-gemini/gemini-cli"
alias p="z"
alias pw="cd ~/src/jbrowse-components/products/jbrowse-web"
alias c="cat"
alias claude="claude --dangerously-skip-permissions"
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
alias rmf="rm -rf"
alias pp="python"
alias gap="git add -p"
alias ga="git add"
alias r="npm run"
alias rscan="npx react-scan@latest http://localhost:3000"
alias lg="lazygit"
alias gti="git"
alias grr="git rebase --continue"
alias gme="git mergetool"
alias rr="npm run dev"
alias mm="git reset --hard origin/main"
alias v="nvim"
alias y="yarn"
alias yl="yarn upgrade-interactive --latest"
alias yu="yarn upgrade"
alias g="git status"
alias gu="git status -uno"
alias oo="npm run dev"
alias gd="git diff"
alias ss="yarn start"
alias fd="fdfind"
alias bn="y build:esm --watch  --preserveWatchOutput"
alias gg="git grep"
alias gm="git commit -m"
alias ggg="git commit --amend --no-edit"
alias gggg="git add . && git commit --amend --no-edit"
alias ggggg="git add . && git commit --amend --no-edit --no-verify"
alias vim="nvim"
alias gp="git add -p"
alias comppng="pngquant *.png; mkdir pngquant; mv *fs8* pngquant; rm *.png;"
alias gc="git checkout"
alias gbb="git checkout -b"
alias ee="cargo run"
alias eee="PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/ cargo run"
alias qq="exit"
alias 00="exit"
alias hh="htop"
alias bb="git branch --sort=-committerdate| fzf |xargs git checkout "
alias bbb="sk |xargs nvim "
alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""
alias upfzf="cd ~/.fzf; git pull; cd -; ~/.fzf/install --all"
alias yy="yarn lint --cache"
alias yyy="yarn lint --cache --fix"
alias ff="PRETTIER_EXPERIMENTAL_CLI=1 yarn format --cache"
alias fff="yy --fix && ff"
alias ttt="yarn tsc --noEmit --watch"
alias tttt="yarn typecheck --noEmit --watch"
alias stp="git subtree push --prefix build origin gh-pages"
alias sau="sudo apt update && sudo apt upgrade"
alias ccc="yarn test --maxWorkers=25%"
alias cccc="yarn test --maxWorkers=25% --watch"
alias ccccc="yarn test --runInBand --watch products/jbrowse-web/src/tests"
alias ydl="youtube-dl"
alias yda="youtube-dl -f 'bestaudio[ext=m4a]' "
alias open="xdg-open"
alias unarx="parallel unar {} ::: *.7z *.rar *.zip"
alias delarx="rm -rf *.zip *.7z *.rar"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias pserver='npx serve -L -S'
alias pserver2='python3 -m http.server'
alias smaller="parallel convert -resize 50% {} resized.{} ::: *.png"
alias cpuspeed="glances --enable-plugin sensors"
alias gitbranch="git log --oneline --graph --all --no-decorate"
alias uprust="rustup update"
alias uprustdeps="cargo install-update -a"
alias upp='nvim --headless "+Lazy! sync" +qa'
alias clean_node_modules="find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +"
alias clean_next="find . -name '.next' -type d -prune -exec rm -rf '{}' +"
alias clean_dist="find . -name 'dist' -type d -prune -exec rm -rf '{}' +"
alias clean_target="find . -name 'target' -type d -prune -exec rm -rf '{}' +"
alias clean_all="clean_node_modules && clean_dist && clean_next && clean_target"
alias uppack="nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'"
alias upall="uprust; uprustdeps; sau;  upfzf; uv self update; yt-dlp -U; upneo.sh; uppack"

pandoc_fzf() {
  local selected_file
  selected_file=$(find . -type f | fzf --prompt="Select file to convert: " --height=40% --border)

  if [[ -n "$selected_file" ]]; then
    pandoc "$selected_file" -t plain --wrap=none | pbcopy
    echo "✓ Converted '$selected_file' to plain text and copied to clipboard"
  else
    echo "No file selected"
  fi
}

function vaporwave() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "$(basename $1 .m4a).vaporwave${2:-0.66}.m4a"
}

function vp() {
  youtube_url="$1"
  effect_rate="${2:-0.66}" # Default effect rate if not provided

  yt-dlp -f 'bestaudio[ext=m4a]' -o - "$youtube_url" |
    ffplay -hide_banner -loglevel error -i pipe:0 -af "asetrate=44100*${effect_rate},aresample=44100"
}

function vaporvideo() {
  ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/${2:-0.66}*PTS[v];[0:a]asetrate=44100*${2:-0.66},aresample=44100[a]" -map "[v]" -map "[a]" "$(basename $1 .mp4).vaporwave${2:-0.66}.mp4"
}

function vaporwaveogg() {
  ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "$(basename $1 .ogg).vaporwave${2:-0.66}.ogg"
}

function sortgff() {
  grep "^#" $1
  grep -v "^#" $1 | sort -t"$(printf '\t')" -k1,1 -k4,4n
}

function rg2() {
  rg --pretty $1 |
    perl -0 -pe 's/\n\n/\n\0/gm' |
    fzf --read0 --ansi --multi --highlight-line --layout reverse |
    perl -ne '/^([0-9]+:|$)/ or print' | xargs nvim
}

function md() {
  pandoc $1 >/tmp/$1.html
  xdg-open /tmp/$1.html
}

function file_ends_with_newline() {
  [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}

function plaintxt() {
  pandoc -i "$1" -t plain --wrap none | pbcopy
}

function cdd() {
  git ls-files | fzf --style full --scheme path \
    --border --padding 1,2 \
    --ghost 'Type in your query' \
    --border-label ' Demo ' --input-label ' Input ' --header-label ' File Type ' \
    --preview 'BAT_THEME=gruvbox-dark fzf-preview.sh {}' \
    --bind 'result:bg-transform-list-label:
        if [[ -z $FZF_QUERY ]]; then
          echo " $FZF_MATCH_COUNT items "
        else
          echo " $FZF_MATCH_COUNT matches for [$FZF_QUERY] "
        fi
        ' \
    --bind 'focus:bg-transform-preview-label:[[ -n {} ]] && printf " Previewing [%s] " {}' \
    --bind 'focus:+bg-transform-header:[[ -n {} ]] && file --brief {}' \
    --bind 'focus:+bg-transform-footer:if [[ -n {} ]]; then
              echo "SHA1:   $(sha1sum < {})"
              echo "SHA256: $(sha256sum < {})"
            fi' \
    --bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' \
    --color 'border:#aaaaaa,label:#cccccc' \
    --color 'preview-border:#9999cc,preview-label:#ccccff' \
    --color 'list-border:#669966,list-label:#99cc99' \
    --color 'input-border:#996666,input-label:#ffcccc' \
    --color 'header-border:#6699cc,header-label:#99ccff' \
    --color 'footer:#ccbbaa,footer-border:#cc9966,footer-label:#cc9966'
}

# Always save commands to history regardless of exit status
zshaddhistory() { return 0 }

export TSC_WATCHFILE=UseFsEventsWithFallbackDynamicPolling
export DEBUG_PRINT_LIMIT=0
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

eval "$(fnm env)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export ANDROID_HOME="$HOME/Android/Sdk"
export PATH=$PATH:~/.local/bin/:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
export SKIM_DEFAULT_COMMAND="fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."

source /etc/profile.d/sra-tools.sh
source ~/.env

# cat out.txt | jq -r 'select(.type == "user") | .message.content'

. "$HOME/.local/bin/env"
eval "$(zoxide init zsh)"

# bun completions
[ -s "/home/cdiesh/.bun/_bun" ] && source "/home/cdiesh/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/home/cdiesh/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

function gencom() {
  git commit -m "$(git diff --cached | claude -p 'Write a conventional commit message for this diff. Format: type(scope): description. Output only the message.')"
}

function chromeclip() {
  pbpaste | sed 's/^[^:]*:[0-9]* //' | pbcopy
}

function fireclip() {
  pbpaste | sed '/^home\//d; /^\[webpack-dev-server\]/d; /^\[HMR\]/d; /^Download the React DevTools/d; /^https:\/\/react.dev/d; s/ home\/[^ ]*:[0-9]\+:[0-9]\+$//' | pbcopy
}

function firefile() {
  sed '/^home\//d; /^\[webpack-dev-server\]/d; /^\[HMR\]/d; /^Download the React DevTools/d; /^https:\/\/react.dev/d; s/ home\/[^ ]*:[0-9]\+:[0-9]\+$//' "$1" | pbcopy
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
