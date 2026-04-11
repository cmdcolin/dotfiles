#!/bin/bash
set -e

echo "Installing macOS development environment..."

xcode-select -p &>/dev/null || xcode-select --install

if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env"

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew install git neovim git-delta ripgrep fnm zoxide fzf lazygit tmux gh fd jq wget htop yt-dlp uv

cargo install ruplacer typos-cli cargo-update

./link.sh mac

echo "✅ macOS setup complete!"
