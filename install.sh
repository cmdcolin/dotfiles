#!/bin/bash
# Unified dotfiles installer
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

echo "🚀 Installing development environment for $OS..."

# 1. Package Managers & Basic Tools
if [[ "$OS" == "mac" ]]; then
  xcode-select -p &>/dev/null || xcode-select --install
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew install git neovim git-delta ripgrep fnm zoxide fzf lazygit tmux gh fd jq wget htop yt-dlp uv
else
  sudo apt update && sudo apt install -y build-essential curl git htop neovim zoxide fzf lazygit tmux gh jq wget
  # On Ubuntu, fd is often 'fdfind'
  sudo apt install -y fd-find || true
fi

# 2. Rust
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env"
cargo install ruplacer typos-cli cargo-update git-delta ripgrep || true

# 3. Version Managers (Linux specific installs)
if [[ "$OS" == "linux" ]]; then
  command -v fnm &>/dev/null || curl -fsSL https://fnm.io/install | bash
  command -v uv &>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
  # Ensure yt-dlp is available (via uv)
  ~/.local/bin/uv tool install yt-dlp || true

  # 3b. Nerd Fonts (Linux)
  echo "📦 Installing Nerd Fonts..."
  fonts="CascadiaCode FiraCode Hack JetBrainsMono UbuntuMono"
  version=$(curl -s 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' | jq -r '.name // "v3.2.1"')
  fonts_dir="${HOME}/.local/share/fonts"
  mkdir -p "$fonts_dir"
  for font in $fonts; do
    if [[ ! -d "$fonts_dir/$font" ]]; then
      echo "Downloading $font ($version)..."
      wget -qO "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${font}.zip"
      unzip -o "/tmp/${font}.zip" -d "$fonts_dir" && rm "/tmp/${font}.zip"
    fi
  done
  find "$fonts_dir" -name 'Windows Compatible' -delete
  command -v fc-cache &>/dev/null && fc-cache -f
fi

# 4. Zsh Prezto
if [[ ! -d ~/.zprezto ]]; then
  git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
fi

# 5. Link dotfiles
./link.sh "$([[ "$OS" == "mac" ]] && echo "mac" || echo "ubuntu")"

echo "✅ Setup complete!"
