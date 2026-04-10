export PNPM_HOME="/Users/colin/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

export TSC_WATCHFILE=UseFsEventsWithFallbackDynamicPolling

alias pw="cd ~/src/jbrowse-components/products/jbrowse-web"

eval "$(brew shellenv zsh)"

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
	open /tmp/$1.html
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
