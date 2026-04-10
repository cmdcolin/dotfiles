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
alias zz="source ~/.zshrc"
alias rmf="rm -rf"
alias grep="grep --color=always"
alias rg="rg --color=always"
alias claude="claude --dangerously-skip-permissions"
alias youtube-dl="yt-dlp"
alias mkenv="python -m venv .venv; source .venv/bin/activate"
alias aenv="source .venv/bin/activate"
alias t="pnpm install"
alias r="npm run"
alias y="yarn"
alias g="git status"
alias gggg="git add . && git commit --amend --no-edit"
alias ggggg="git add . && git commit --amend --no-edit --no-verify"
alias mm='read -p "🔥 Reset to origin/main? (y/n) " -n1; echo; [[ $REPLY =~ ^[Yy]$ ]] && git reset --hard origin/main || echo "Cancelled"'
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
alias lg="lazygit"
alias bb="git branch --sort=-committerdate| fzf |xargs git checkout "
alias bbb="sk |xargs nvim "
alias clean_all="find . -name 'node_modules' -o -name '.next' -o -name 'dist' -o -name 'target' | xargs rm -rf"
alias hh="htop"
alias qq="exit"
alias ee="cargo run"
alias ss="yarn start"
alias rr="npm run dev"
alias p="z"
alias ff="PRETTIER_EXPERIMENTAL_CLI=1 yarn format --cache"
alias pserver='npx serve'

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

function upall() {
	rustup update
	cargo install-update -a
	cd ~/.fzf && git pull && cd - && ~/.fzf/install --all
	uv self update
	yt-dlp -U
	nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'

	if [[ "$OSTYPE" == "darwin"* ]]; then
		brew upgrade
	elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
		sudo apt update && sudo apt upgrade
	fi
}

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000
