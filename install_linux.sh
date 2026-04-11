#!/bin/bash
set -e

echo "Installing Ubuntu/Linux development environment..."

sudo apt update
sudo apt install -y build-essential curl git htop

if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env"

sudo apt install -y neovim git zoxide fzf lazygit tmux gh fd-find jq wget

cargo install git-delta ruplacer ripgrep typos-cli cargo-update

# fnm (Node version manager)
curl -fsSL https://fnm.io/install | bash

# uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

if [[ ! -d ~/.zprezto ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
fi

# yt-dlp
uv tool install yt-dlp

./link.sh ubuntu

echo "✅ Ubuntu/Linux setup complete!"
