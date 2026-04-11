# Must come before the tmux exec: skips this file for non-interactive shells
# (scripts, scp, rsync over SSH) so they don't accidentally spawn tmux.
[[ $- != *i* ]] && return

# -2 forces 256-color mode regardless of $TERM.
[[ -z "$TMUX" ]] && exec tmux -2

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
	source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export EDITOR="nvim"

alias e="nvim"
alias zz="source ~/.zshrc"
alias rmf="rm -rf"

# Skips the per-tool-call permissions prompt.
alias claude="claude --dangerously-skip-permissions"

alias mkenv="python -m venv .venv; source .venv/bin/activate"
alias aenv="source .venv/bin/activate"

alias y="pnpm"
alias g="git status"
alias yy="pnpm lint --cache"
alias yyy="pnpm lint --cache --fix"
alias ttt="pnpm exec tsc --noEmit --watch"
alias fff="yy --fix && ff"

# Stage everything and amend last commit — useful for "oops, forgot a file".
alias gggg="git add . && git commit --amend --no-edit"

# Hard-reset to origin/main with a confirmation prompt.
alias mm='read -p "🔥 Reset to origin/main? (y/n) " -n1; echo; [[ $REPLY =~ ^[Yy]$ ]] && git reset --hard origin/main || echo "Cancelled"'

# Amends last commit to prepend [skip ci], preventing a CI run on push.
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'

alias lg="lazygit"

# Sorted by most recently committed so fresh branches float to the top.
alias bb="git branch --sort=-committerdate| fzf |xargs git checkout "

# -type d -prune stops find from descending into found dirs, avoiding
# nested matches (e.g. node_modules inside node_modules).
alias clean_all="find . \( -name 'node_modules' -o -name '.next' -o -name 'dist' -o -name 'target' \) -type d -prune -exec rm -rf {} +"

alias hh="htop"
alias qq="exit"
alias ee="cargo run"
alias ss="pnpm start"
alias rr="pnpm run dev"
alias p="z"
alias ff="pnpm format --cache"
alias pserver='npx serve'

# Slow down audio to a vaporwave pitch/speed (default 0.66x).
# asetrate fakes a slowdown by changing the declared sample rate without
# resampling — then aresample brings it back to 44100 so players handle it.
# Usage: vaporwave input.m4a [rate]
function vaporwave() {
	ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "$(basename $1 .m4a).vaporwave${2:-0.66}.m4a"
}

# Stream a YouTube URL through yt-dlp → ffplay with vaporwave pitch effect.
# Usage: vp <youtube-url> [rate]
function vp() {
	youtube_url="$1"
	effect_rate="${2:-0.66}"

	yt-dlp -f 'bestaudio[ext=m4a]' -o - "$youtube_url" |
		ffplay -hide_banner -loglevel error -i pipe:0 -af "asetrate=44100*${effect_rate},aresample=44100"
}

# setpts=1/rate*PTS slows video frame timestamps; audio uses the same asetrate trick.
# Usage: vaporvideo input.mp4 [rate]
function vaporvideo() {
	ffmpeg -i "$1" -filter_complex "[0:v]setpts=1/${2:-0.66}*PTS[v];[0:a]asetrate=44100*${2:-0.66},aresample=44100[a]" -map "[v]" -map "[a]" "$(basename $1 .mp4).vaporwave${2:-0.66}.mp4"
}

function vaporwaveogg() {
	ffmpeg -i "$1" -af "asetrate=44100*${2:-0.66},aresample=44100" "$(basename $1 .ogg).vaporwave${2:-0.66}.ogg"
}

# Prints comment lines first, then data rows sorted by chromosome (col 1)
# and start position (col 4, numeric).
function sortgff() {
	grep "^#" "$1"
	grep -v "^#" "$1" | sort -t"$(printf '\t')" -k1,1 -k4,4n
}

# ripgrep → fzf multi-select → nvim. The perl passes convert rg's blank-line
# separators into null bytes so fzf treats each file block as one item.
# The second perl strips line-number prefixes, leaving only filenames for nvim.
function rg2() {
	rg --pretty $1 |
		perl -0 -pe 's/\n\n/\n\0/gm' |
		fzf --read0 --ansi --multi --highlight-line --layout reverse |
		perl -ne '/^([0-9]+:|$)/ or print' | xargs nvim
}

# By default zsh drops commands that exit non-zero from history.
zshaddhistory() { return 0 }

export DEBUG_PRINT_LIMIT=0

# Sparse protocol fetches only the index entries you actually need, much
# faster than the legacy git-based full-clone approach.
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

# Opt into Prettier's v3 CLI rewrite. Remove once it becomes the default.
export PRETTIER_EXPERIMENTAL_CLI=1

eval "$(fnm env)"

# Ctrl-R history search, Ctrl-T file picker, Alt-C directory jump.
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
fi
export PATH=$PATH:~/.local/bin/

[ -f ~/.env ] && source ~/.env

eval "$(zoxide init zsh)"

# cargo install-update -a requires the cargo-update crate to be installed first.
function upall() {
	echo "Updating Rust..."
	rustup update
	cargo install-update -a

	if [[ -d ~/.fzf/.git ]]; then
		echo "Updating fzf..."
		(cd ~/.fzf && git pull) && ~/.fzf/install --all
	fi

	echo "Updating CLI tools..."
	uv self update
	yt-dlp -U

	echo "Updating Neovim plugins..."
	nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'

	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo "Updating Homebrew packages..."
		brew update
		brew upgrade
		brew cleanup
	elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
		echo "Updating apt packages..."
		sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
	fi

	echo "✅ All updates complete!"
}

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

# Machine-specific overrides sourced last so they can override anything above.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
