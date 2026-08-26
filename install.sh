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
  brew install git neovim git-delta ripgrep fnm zoxide tmux gh fd jq wget htop uv miniserve
  log_success "macOS dependencies installed via Homebrew."
}

# Get pinentry-tty without root: download the .deb and extract just the binary
# into ~/.local/bin. Its shared libs (libassuan, libgpg-error) already ship with
# the other pinentry packages, so the extracted binary runs as-is. The
# pinentry-auto wrapper prefers it so tmux/ssh signing prompts inline instead of
# drawing a full-screen ncurses box.
ensure_pinentry_tty_userlocal() {
  command -v pinentry-tty &>/dev/null && return 0
  command -v apt-get &>/dev/null && command -v dpkg-deb &>/dev/null || return 0
  local tmp
  tmp="$(mktemp -d)"
  if (cd "$tmp" && apt-get download pinentry-tty && dpkg-deb -x pinentry-tty*.deb x) &>/dev/null &&
    [[ -x "$tmp/x/usr/bin/pinentry-tty" ]]; then
    mkdir -p "$HOME/.local/bin"
    install -m755 "$tmp/x/usr/bin/pinentry-tty" "$HOME/.local/bin/pinentry-tty"
    log_success "pinentry-tty installed user-locally (~/.local/bin)"
  fi
  rm -rf "$tmp"
}

setup_linux_deps_via_apt() {
  log_info "Attempting to install Linux dependencies via apt..."
  if [[ "$HOST" == "labserver" ]]; then
    log_info "⚠️  Labserver: skipping sudo apt, using user-local installs only"
    ensure_pinentry_tty_userlocal
    return 0
  fi
  if ! command -v sudo &>/dev/null || ! command -v apt &>/dev/null; then
    log_error "Sudo or apt not found/available. Skipping apt installations."
    log_info "Essential Linux tools might need to be installed manually or via alternative methods."
    ensure_pinentry_tty_userlocal
    return 1
  fi
  log_info "Running apt update and install..."
  sudo apt update
  # One package at a time: gh isn't in every release's repos, and a
  # single missing name would otherwise abort the whole install.
  for pkg in build-essential curl git htop zoxide tmux gh jq wget ninja-build gettext cmake unzip fd-find fzf ripgrep xclip pinentry-tty; do
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

# Labserver allows no apt/brew/cargo, so the tools that would otherwise come
# from cargo are fetched as static musl binaries instead. Projects disagree on
# whether the tarball has a top-level directory, so the binary is located by
# name after extraction rather than by a hardcoded path.
install_prebuilt_binary() {
  local repo=$1 bin=$2 url tmp found
  if command -v "$bin" &>/dev/null; then
    log_info "$bin already installed. Skipping."
    return 0
  fi
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
    grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 |
    grep -E 'x86_64-unknown-linux-musl\.tar\.gz$' | head -1)
  if [[ -z "$url" ]]; then
    log_error "No musl asset for $repo (rate limited?). Skipping $bin."
    return 1
  fi
  tmp=$(mktemp -d)
  if curl -fsSL "$url" -o "$tmp/asset.tar.gz" && tar -xzf "$tmp/asset.tar.gz" -C "$tmp"; then
    found=$(find "$tmp" -type f -name "$bin" | head -1)
  fi
  if [[ -n "${found:-}" ]]; then
    install -m755 "$found" "$HOME/.local/bin/$bin"
    log_success "$bin installed from $repo."
  else
    log_error "No '$bin' binary inside $url."
  fi
  rm -rf "$tmp"
}

install_labserver_prebuilts() {
  if [[ "$(uname -m)" != "x86_64" ]]; then
    log_info "Not x86_64 — skipping prebuilt binaries."
    return 0
  fi
  log_info "Installing prebuilt binaries in place of the cargo tools..."
  install_prebuilt_binary BurntSushi/ripgrep rg || true
  install_prebuilt_binary sharkdp/fd fd || true
  install_prebuilt_binary ajeetdsouza/zoxide zoxide || true
  install_prebuilt_binary dandavison/delta delta || true
}

install_fnm() {
  log_info "Installing FNM (Node Version Manager)..."
  if ! command -v fnm &>/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash || true
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

# Not part of link.sh: the statusline is compiled and lands in a config dir that
# varies per profile. sync-profiles.sh builds it into every ~/.claude* and
# points that profile's settings.json at its own copy. Profiles only exist once
# Claude has been run, so on a fresh machine this does nothing and wants a
# re-run afterwards.
setup_claude_profiles() {
  log_info "Setting up Claude profiles and statusline..."
  if ! command -v python3 &>/dev/null; then
    log_error "python3 not found. Skipping Claude profile sync."
    return 1
  fi
  "$DOTFILES_DIR/claude/sync-profiles.sh"
  log_success "Claude profiles synced."
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
  else
    install_labserver_prebuilts
  fi
  install_fnm
  install_uv_and_yt_dlp
  install_fzf
  install_neovim || log_info "Continuing without Neovim."
  install_fonts

  install_zprezto
  link_dotfiles
  setup_claude_profiles || log_info "Continuing without the Claude statusline."

  log_success "Environment setup complete!"
  log_info "Please restart your shell or source your shell configuration file (e.g., 'source ~/.zshrc') for all changes to take effect."
}

main "$@"
