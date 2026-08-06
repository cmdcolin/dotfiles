#!/bin/bash
set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
  # Freshly installed tools land here; put it on PATH now so later steps in this
  # same run can call them without a shell restart.
  export PATH="$HOME/.local/bin:$HOME/.local/share/fnm:$PATH"
  log_success "Local bin directory created."
}

setup_macos_deps_via_brew() {
  log_info "Attempting to install macOS dependencies via Homebrew..."
  if ! command -v brew &>/dev/null; then
    log_info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log_info "Installing essential macOS tools via Homebrew..."
  # No fzf: install_fzf clones ~/.fzf for its own binary and the ~/.fzf.zsh
  # that .zshrc sources, so a brew copy is a second, unused fzf on PATH.
  brew install git neovim git-delta ripgrep fnm zoxide lazygit tmux gh fd jq wget htop uv miniserve
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
  # One package at a time: lazygit/gh aren't in every release's repos, and a
  # single missing name would otherwise abort the whole install.
  for pkg in build-essential curl git htop zoxide lazygit tmux gh jq wget ninja-build gettext cmake unzip fd-find fzf ripgrep xclip; do
    sudo apt install -y "$pkg" || log_error "apt: $pkg unavailable, skipping."
  done
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
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  log_info "Installing Cargo tools..."
  local tools=(ruplacer typos-cli cargo-update)
  # No apt packages for these; on mac brew already supplied them.
  [[ "$OS" == "mac" ]] || tools+=(git-delta ripgrep miniserve)
  cargo install --locked "${tools[@]}" || log_info "Some Cargo tools failed to install, might be optional."
  log_success "Rust and Cargo tools installed."
}

install_fnm() {
  log_info "Installing FNM (Node Version Manager)..."
  if ! command -v fnm &>/dev/null; then
    curl -fsSL https://fnm.io/install | bash
    hash -r
  fi
  command -v fnm &>/dev/null && eval "$(fnm env)"
  log_success "FNM installed."
}

install_uv_and_yt_dlp() {
  log_info "Installing UV (Python Tool Manager)..."
  if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    hash -r
  else
    log_info "UV already installed. Update is usually handled by 'uv tool install'."
  fi

  if ! command -v uv &>/dev/null; then
    log_error "uv not on PATH after install. Skipping yt-dlp."
    return 0
  fi
  log_info "Installing yt-dlp using UV..."
  uv tool install yt-dlp
  log_success "yt-dlp installed."
}

install_fzf() {
  # brew/apt provide fzf; the git clone is only for hosts with no package manager.
  if command -v fzf &>/dev/null || [[ -d ~/.fzf ]]; then
    log_info "FZF already installed. Skipping."
    return 0
  fi
  log_info "Installing FZF (Fuzzy Finder)..."
  git clone --depth 1 "$FZF_REPO" ~/.fzf
  ~/.fzf/install --bin
  log_success "FZF installed."
}

install_neovim() {
  if command -v nvim &>/dev/null; then
    log_info "Neovim already installed. Skipping."
    return 0
  fi

  if [[ "$HOST" == "labserver" ]]; then
    log_info "Installing Neovim pre-built binary..."
    local version tarball install_dir
    version=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$version" ]]; then
      log_error "Could not resolve latest Neovim release (rate limited?)."
      return 1
    fi
    tarball="nvim-linux-x86_64.tar.gz"
    install_dir="$HOME/.local/nvim"
    curl -sSL "https://github.com/neovim/neovim/releases/download/${version}/${tarball}" -o "/tmp/${tarball}"
    rm -rf "$install_dir" && mkdir -p "$install_dir"
    tar -xzf "/tmp/${tarball}" -C "$install_dir" --strip-components=1
    rm "/tmp/${tarball}"
    ln -sf "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"
    log_success "Neovim ${version} installed."
    return 0
  fi

  log_info "Compiling Neovim from source..."
  if ! command -v make &>/dev/null || ! command -v cmake &>/dev/null; then
    log_error "make and cmake are required to compile Neovim."
    return 1
  fi
  if [[ ! -d "$NEOVIM_SRC_DIR" ]]; then
    git clone https://github.com/neovim/neovim.git "$NEOVIM_SRC_DIR"
  else
    (cd "$NEOVIM_SRC_DIR" && git pull origin master && git submodule update --init)
  fi
  mkdir -p "$NVIM_INSTALL_PREFIX/bin"
  (cd "$NEOVIM_SRC_DIR" && make clean && make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$NVIM_INSTALL_PREFIX" install)
  log_success "Neovim compiled and installed."
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
  "$DOTFILES_DIR/link.sh"
  log_success "Dotfiles linked."
}

main() {
  detect_os
  get_host "$1"
  setup_environment

  # A step that reports it is skipping returns non-zero; under set -e that would
  # abort the whole run, so the optional ones are explicitly tolerated.
  if [[ "$OS" == "mac" ]]; then
    setup_macos_deps_via_brew
  else
    setup_linux_deps_via_apt || log_info "Continuing without apt packages."
  fi

  if [[ "$HOST" != "labserver" ]]; then
    install_rust_and_cargo_tools
  fi
  install_fnm
  install_uv_and_yt_dlp
  install_fzf
  install_neovim || log_info "Continuing without Neovim."
  install_fonts

  install_zprezto
  link_dotfiles

  log_success "Environment setup complete!"
  log_info "Please restart your shell or source your shell configuration file (e.g., 'source ~/.zshrc') for all changes to take effect."
}

main "$@"
