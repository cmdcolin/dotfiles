#!/bin/bash
set -e

echo "Installing macOS development environment..."

echo "Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || true

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Ensure Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Core tools
brew install git
brew install neovim
brew install git-delta
brew install ripgrep
brew install fnm
brew install zoxide
brew install fzf
brew install lazygit
brew install tmux
brew install gh
brew install awscli
brew install fd
brew install jq
brew install wget

# Cargo tools
cargo install ruplacer typos

# Link dotfiles with macOS config
./link.sh mac

# Install zprezto for zsh configuration
echo "Installing zprezto..."
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

echo "✅ macOS setup complete!"
