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
alias pzip="pigz"
alias pgzip="bgzip -@8"
alias gemini="gemini --yolo"
alias grep="grep --color=always"
alias claude="claude --dangerously-skip-permissions"
alias rg="rg --color=always"
alias zz="source ~/.zshrc"
alias e="nvim"
alias python="python3"
alias vm="nvim"
alias t="pnpm install"
alias rmf="rm -rf"
alias gemmy="npx https://github.com/google-gemini/gemini-cli"
alias p="z"
alias c="cat"
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
alias youtube-dl="yt-dlp"
alias pp="python"
alias r="npm run"
alias rscan="npx react-scan@latest http://localhost:3000"
alias lg="lazygit"
alias rr="npm run dev"
alias g="git status"
alias mm='read -p "🔥 Reset to origin/main? (y/n) " -n1; echo; [[ $REPLY =~ ^[Yy]$ ]] && git reset --hard origin/main || echo "Cancelled"'
alias v="nvim"
alias y="yarn"
alias yl="yarn upgrade-interactive --latest"
alias yu="yarn upgrade"
alias oo="npm run dev"
alias ss="yarn start"
alias bn="y build:esm --watch  --preserveWatchOutput"
alias vim="nvim"
alias gggg="git add . && git commit --amend --no-edit"
alias ggggg="git add . && git commit --amend --no-edit --no-verify"
alias ee="cargo run"
alias qq="exit"
alias 00="exit"
alias hh="htop"
alias bb="git branch --sort=-committerdate| fzf |xargs git checkout "
alias bbb="sk |xargs nvim "
alias upfzf="cd ~/.fzf; git pull; cd -; ~/.fzf/install --all"
alias yy="yarn lint --cache"
alias yyy="yarn lint --cache --fix"
alias ff="PRETTIER_EXPERIMENTAL_CLI=1 yarn format --cache"
alias fff="yy --fix && ff"
alias ttt="yarn tsc --noEmit --watch"
alias ccc="yarn test --maxWorkers=25%"
alias ydl="youtube-dl"
alias yda="youtube-dl -f 'bestaudio[ext=m4a]' "
alias unarx="parallel unar {} ::: *.7z *.rar *.zip"
alias delarx="rm -rf *.zip *.7z *.rar"
alias pserver='npx serve'
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

# Always save commands to history regardless of exit status
zshaddhistory() { return 0 }

export DEBUG_PRINT_LIMIT=0
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

eval "$(fnm env)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export ANDROID_HOME="$HOME/Android/Sdk"
export PATH=$PATH:~/.local/bin/:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
export SKIM_DEFAULT_COMMAND="fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."

source ~/.env

eval "$(zoxide init zsh)"

function gencom() {
  git commit -m "$(git diff --cached | claude -p 'Write a conventional commit message for this diff. Format: type(scope): description. Output only the message.')"
}

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000
