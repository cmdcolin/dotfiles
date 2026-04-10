#!/bin/bash
set -e

echo "Installing Ubuntu/Linux development environment..."

sudo apt update
sudo apt install -y build-essential curl git

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Core tools via apt
sudo apt install -y neovim git zoxide fzf lazygit tmux gh fd-find jq wget

# Tools via cargo
cargo install git-delta ruplacer ripgrep typos

# AWS CLI via apt
sudo apt install -y awscli

# fnm (Node version manager)
curl -fsSL https://fnm.io/install | bash

# Link dotfiles with Linux config
./link.sh ubuntu

echo "✅ Ubuntu/Linux setup complete!"
