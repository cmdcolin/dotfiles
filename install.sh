#!/bin/bash
set -e

OS="linux"
[[ "$OSTYPE" == "darwin"* ]] && OS="mac"

echo "🚀 Installing for $OS..."
mkdir -p "$HOME/.local/bin"

if [[ "$OS" == "mac" ]]; then
  xcode-select -p &>/dev/null || xcode-select --install
  command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git neovim git-delta ripgrep fnm zoxide fzf lazygit tmux gh fd jq wget htop yt-dlp uv
else
  sudo apt update
  sudo apt install -y build-essential curl git htop zoxide lazygit tmux gh jq wget \
    ninja-build gettext cmake unzip fd-find
  ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
fi

command -v rustup &>/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install ruplacer typos-cli cargo-update git-delta ripgrep || true

if [[ "$OS" == "linux" ]]; then
  command -v fnm &>/dev/null || curl -fsSL https://fnm.io/install | bash
  command -v uv &>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
  command -v yt-dlp &>/dev/null || "$HOME/.local/bin/uv" tool install yt-dlp || true

  [[ ! -d ~/.fzf ]] && git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all

  if [[ ! -d ~/src/neovim ]]; then
    mkdir -p ~/src
    git clone https://github.com/neovim/neovim ~/src/neovim
    (cd ~/src/neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local" install)
  fi

  echo "📦 Installing fonts..."
  fonts_dir="${HOME}/.local/share/fonts"
  mkdir -p "$fonts_dir"
  for font in CascadiaCode JetBrainsMono; do
    if [[ ! -d "$fonts_dir/$font" ]]; then
      wget -qO "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
      unzip -o "/tmp/${font}.zip" -d "$fonts_dir" && rm "/tmp/${font}.zip"
    fi
  done
  command -v fc-cache &>/dev/null && fc-cache -f
fi

[[ ! -d ~/.zprezto ]] && git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto

./link.sh "$([[ "$OS" == "mac" ]] && echo "mac" || echo "ubuntu")"

echo "✅ Done!"
