#!/bin/bash
set -e

echo "Installing Ubuntu/Linux development environment..."

sudo apt update
sudo apt install -y build-essential curl git htop

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

sudo apt install -y neovim git zoxide fzf lazygit tmux gh fd-find jq wget

cargo install git-delta ruplacer ripgrep typos cargo-update

# fnm (Node version manager)
curl -fsSL https://fnm.io/install | bash

# uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# yt-dlp
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ~/.local/bin/yt-dlp
chmod +x ~/.local/bin/yt-dlp

./link.sh ubuntu

echo "✅ Ubuntu/Linux setup complete!"
