#!/bin/bash
set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

# Package Managers
HOST="${1:-$OS}"
echo "🚀 Installing for $HOST..."

if [[ "$OS" == "mac" ]]; then
  xcode-select -p &>/dev/null || xcode-select --install
  command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git neovim git-delta ripgrep fnm zoxide fzf lazygit tmux gh fd jq wget htop yt-dlp uv
else
  # Linux Essentials
  PKGS="build-essential curl git htop tmux wget jq"
  [[ "$HOST" != "labserver" ]] && PKGS="$PKGS neovim fzf lazygit gh"
  sudo apt update && sudo apt install -y $PKGS || echo "⚠️  Apt failed (likely no sudo), continuing..."
fi

# Rust & Tools
command -v rustup &>/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install ruplacer typos-cli cargo-update git-delta ripgrep zoxide fd-find || true

# Version Managers & CLI Tools
if [[ "$OS" == "linux" ]]; then
  # fnm
  if ! command -v fnm &>/dev/null; then
    curl -fsSL https://fnm.io/install | bash
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
  fi
  fnm install --lts && fnm use --lts

  # uv
  command -v uv &>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  uv tool install yt-dlp || true

  # fzf
  [[ ! -d ~/.fzf ]] && git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all
fi

# Prezto & Link
[[ ! -d ~/.zprezto ]] && git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
./link.sh "$HOST"

echo "✅ Done!"
