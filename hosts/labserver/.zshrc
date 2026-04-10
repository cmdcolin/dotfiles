export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

alias sau="sudo apt update && sudo apt upgrade"
alias eee="PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/ cargo run"
alias ww="watch -n.1 \"cat /proc/cpuinfo | grep \\\"^[c]pu MHz\\\"\""

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

. "$HOME/.local/bin/env"

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

function pandoc_fzf() {
	local selected_file
	selected_file=$(find . -type f | fzf --prompt="Select file to convert: " --height=40% --border)

	if [[ -n "$selected_file" ]]; then
		pandoc "$selected_file" -t plain --wrap=none | pbcopy
		echo "✓ Converted '$selected_file' to plain text and copied to clipboard"
	else
		echo "No file selected"
	fi
}

function md() {
	pandoc "$1" >/tmp/$1.html
	xdg-open /tmp/$1.html
}

function plaintxt() {
	pandoc -i "$1" -t plain --wrap none | pbcopy
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
