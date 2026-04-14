# Basic setup
[[ $- != *i* ]] && return
[[ -z "$TMUX" ]] && exec tmux
[[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]] && source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

# Path & Environment
export EDITOR="nvim"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/fnm:$PATH"
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
export PNPM_HOME="$([[ "$OSTYPE" == "darwin"* ]] && echo "$HOME/Library/pnpm" || echo "$HOME/.local/share/pnpm")"
[[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"

# Aliases: Core
alias e="nvim"
alias zz="source ~/.zshrc"
alias rmf="rm -rf"
alias g="git status"
alias lg="lazygit"
alias hh="htop"
alias qq="exit"
alias p="z"

# Aliases: Node/JS
alias y="pnpm"
alias yy="pnpm lint --cache"
alias yyy="pnpm lint --cache --fix"
alias ttt="pnpm exec tsc --noEmit --watch"
alias ff="pnpm format --cache"
alias ss="pnpm start"
alias rr="pnpm run dev"

# Aliases: Git Helpers
alias gggg="git add . && git commit --amend --no-edit"
alias mm='read -q "REPLY?🔥 Reset to origin/main? (y/n) "; echo; [[ $REPLY =~ ^[Yy]$ ]] && git reset --hard origin/main'
alias skipci='git commit --amend --no-edit -m "[skip ci] $(git log -1 --pretty=%B)"'
alias bb="git branch --sort=-committerdate | fzf | xargs git checkout"

# Version Managers & Integrations
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.cargo/env ] && source ~/.cargo/env
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Helpers
function upall() {
  rustup update && cargo install-update -a
  command -v uv &>/dev/null && uv self update
  command -v yt-dlp &>/dev/null && yt-dlp -U
  nvim --headless -c 'lua vim.pack.update(nil, {force=true})' -c 'qa'
  [[ "$OSTYPE" == "darwin"* ]] && (brew update && brew upgrade)
  echo "✅ Updated."
}

# Machine-specific overrides sourced last so they can override anything above.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
