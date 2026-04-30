#!/bin/bash
set -eo pipefail

ZPREZTO_REPO="https://github.com/sorin-ionescu/prezto.git"
NEOVIM_SRC_DIR="$HOME/src/neovim"
NVIM_INSTALL_PREFIX="$HOME/.local"
FONTS_DIR="${HOME}/.local/share/fonts"
FZF_REPO="https://github.com/junegunn/fzf.git"

log_info() { echo "INFO: $*"; }
log_success() { echo "✅ $*"; }
log_error() { echo "❌ ERROR: $*" >&2; }

detect_os() {
  OS="linux"
  [[ "$OSTYPE" == "darwin"* ]] && OS="mac"
  log_info "Detected OS: $OS"
}

get_host() {
  HOST="${1:-}"
  if [[ -z "$HOST" ]]; then
    [[ "$OS" == "mac" ]] && HOST="mac" || HOST="ubuntu"
  fi
}

setup_environment() {
  log_info "Setting up environment..."
  mkdir -p "$HOME/.local/bin"
  log_success "Local bin directory created."
}

setup_macos_deps_via_brew() {
  log_info "Attempting to install macOS dependencies via Homebrew..."
  if ! command -v brew &>/dev/null; then
    log_info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log_info "Installing essential macOS tools via Homebrew..."
  brew install git neovim git-delta ripgrep fnm zoxide fzf lazygit tmux gh fd jq wget htop yt-dlp uv miniserve
  log_success "macOS dependencies installed via Homebrew."
}

setup_linux_deps_via_apt() {
  log_info "Attempting to install Linux dependencies via apt..."
  if [[ "$HOST" == "labserver" ]]; then
    log_info "⚠️  Labserver: skipping sudo apt, using user-local installs only"
    return 0
  fi
  if ! command -v sudo &>/dev/null || ! command -v apt &>/dev/null; then
    log_error "Sudo or apt not found/available. Skipping apt installations."
    log_info "Essential Linux tools might need to be installed manually or via alternative methods."
    return 1
  fi
  log_info "Running apt update and install..."
  sudo apt update
  sudo apt install -y build-essential curl git htop zoxide lazygit tmux gh jq wget ninja-build gettext cmake unzip fd-find
  if [[ -f /usr/bin/fdfind ]]; then
    ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
  else
    log_info "fdfind not found in /usr/bin, skipping symlink."
  fi
  log_success "Linux dependencies installed via apt."
}

install_rust_and_cargo_tools() {
  log_info "Installing Rust and Cargo..."
  if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  else
    log_info "Rustup already installed. Updating..."
    rustup update
  fi
  source "$HOME/.cargo/env"
  log_info "Installing Cargo tools..."
  cargo install ruplacer typos-cli cargo-update git-delta ripgrep miniserve || log_info "Some Cargo tools failed to install, might be optional."
  log_success "Rust and Cargo tools installed."
}

install_fnm() {
  log_info "Installing FNM (Node Version Manager)..."
  if ! command -v fnm &>/dev/null; then
    curl -fsSL https://fnm.io/install | bash
    eval "$(fnm env)"
  else
    log_info "FNM already installed. Updating..."
    fnm self-update
  fi
  log_success "FNM installed."
}

install_uv_and_yt_dlp() {
  log_info "Installing UV (Python Tool Manager)..."
  if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    if ! command -v uv &>/dev/null; then
      export PATH="$HOME/.local/bin:$PATH"
    fi
  else
    log_info "UV already installed. Update is usually handled by 'uv tool install'."
  fi
  log_success "UV installed."

  log_info "Installing yt-dlp using UV..."
  uv tool install yt-dlp
  log_success "yt-dlp installed."
}

install_fzf() {
  log_info "Installing FZF (Fuzzy Finder)..."
  if [[ ! -d ~/.fzf ]]; then
    git clone --depth 1 "$FZF_REPO" ~/.fzf
    ~/.fzf/install --all
  else
    log_info "FZF already installed. Skipping."
  fi
  log_success "FZF installed."
}

install_neovim() {
  log_info "Installing Neovim from master branch (nightly) by compiling from source..."

  if command -v nvim &>/dev/null; then
    log_info "Neovim is already installed and available in PATH. Skipping compilation."
    return 0
  fi

  if [[ "$OS" == "linux" ]]; then
    if ! command -v make &>/dev/null || ! command -v cmake &>/dev/null || ! command -v git &>/dev/null; then
      log_error "Make, CMake, and Git are required for compiling Neovim on Linux. Please ensure they are installed via apt."
      return 1
    fi
  elif [[ "$OS" == "mac" ]]; then
    if ! command -v make &>/dev/null || ! command -v cmake &>/dev/null || ! command -v git &>/dev/null; then
      log_error "Make, CMake, and Git are required for compiling Neovim on macOS. Please ensure they are installed via brew."
      return 1
    fi
  fi

  local NVIM_BIN_PATH="$NVIM_INSTALL_PREFIX/bin/nvim"

  log_info "Cloning or updating Neovim from master branch..."
  if [[ ! -d "$NVIM_SRC_DIR" ]]; then
    git clone https://github.com/neovim/neovim.git "$NVIM_SRC_DIR"
  else
    log_info "Updating existing Neovim source directory..."
    (cd "$NVIM_SRC_DIR" && git pull origin master && git submodule update --init)
  fi

  if [[ "$HOST" == "labserver" ]]; then
    log_info "Labserver: skipping Neovim compilation from source (use system package if needed)"
    return 0
  fi

  log_info "Compiling Neovim..."
  mkdir -p "$NVIM_INSTALL_PREFIX/bin"
  (cd "$NVIM_SRC_DIR" && make clean && make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$NVIM_INSTALL_PREFIX" install)

  if [[ -f "$NVIM_BIN_PATH" ]]; then
    log_success "Neovim compiled and installed. Binary is at $NVIM_BIN_PATH."
  else
    log_error "Neovim compilation failed or binary not found at $NVIM_BIN_PATH."
    return 1
  fi
  log_success "Neovim installation/update complete."
}

install_fonts() {
  if [[ "$OS" == "linux" ]] && [[ "$HOST" != "labserver" ]]; then
    log_info "Installing fonts..."
    mkdir -p "$FONTS_DIR"
    for font in CascadiaCode JetBrainsMono; do
      if [[ ! -d "$FONTS_DIR/$font" ]]; then
        log_info "Downloading ${font} font..."
        wget -qO "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
        unzip -o "/tmp/${font}.zip" -d "$FONTS_DIR" && rm "/tmp/${font}.zip"
      fi
    done
    command -v fc-cache &>/dev/null && fc-cache -f
    log_success "Fonts installed."
  else
    log_info "Skipping font installation (non-Linux OS or labserver)."
  fi
}

install_zprezto() {
  log_info "Installing Zprezto..."
  if [[ ! -d ~/.zprezto ]]; then
    git clone --recursive "$ZPREZTO_REPO" ~/.zprezto
  else
    log_info "Zprezto already installed. Skipping."
  fi
  log_success "Zprezto installed."
}

link_dotfiles() {
  log_info "Linking dotfiles..."
  ./link.sh "$HOST"
  log_success "Dotfiles linked."
}

main() {
  detect_os
  get_host "$1"
  setup_environment

  if [[ "$OS" == "mac" ]]; then
    if command -v brew &>/dev/null; then
      log_info "Homebrew found. Installing macOS dependencies..."
      setup_macos_deps_via_brew
    else
      log_info "Homebrew not found. Skipping brew installations."
      log_info "Essential macOS tools might need to be installed manually."
    fi
  else
    if command -v sudo &>/dev/null && command -v apt &>/dev/null; then
      log_info "Sudo and apt found. Installing Linux dependencies via apt..."
      setup_linux_deps_via_apt
    else
      log_info "Sudo or apt not found/available. Skipping apt installations."
      log_info "Essential Linux tools might need to be installed manually or via alternative methods."
    fi
  fi

  install_rust_and_cargo_tools
  install_fnm
  install_uv_and_yt_dlp
  install_fzf
  install_neovim
  install_fonts

  install_zprezto
  link_dotfiles

  log_success "Environment setup complete!"
  log_info "Please restart your shell or source your shell configuration file (e.g., 'source ~/.zshrc') for all changes to take effect."
}

main "$@"
