#!/bin/bash
set -e

echo "🚀 Setting up labserver environment locally..."

# Ensure essential utilities are present
# Assumes git and curl are already installed on the labserver system.
# If not, these would need to be installed via a system package manager first.
if ! command -v git &>/dev/null; then
    echo "Error: git is not installed. Please install git first."
    exit 1
fi
if ! command -v curl &>/dev/null; then
    echo "Error: curl is not installed. Please install curl first."
    exit 1
fi

echo "Creating local bin directory..."
mkdir -p "$HOME/.local/bin"

# --- Zoxide Installation ---
echo "Installing zoxide..."
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
echo "✅ zoxide installed."

# --- FNM (Node Version Manager) Installation ---
echo "Installing fnm..."
curl -fsSL https://fnm.io/install | bash
# FNM adds itself to PATH during its install script, but it might need to be sourced
# to be immediately usable in the current script execution context.
eval "$(fnm env)"
echo "✅ fnm installed."

# --- UV (Python Package/Tool Manager) Installation ---
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
# uv's install script usually adds itself to PATH. Ensure it's available.
# If not, it might be in $HOME/.local/bin/uv
if ! command -v uv &>/dev/null; then
    echo "uv command not found after installation. Assuming it's in $HOME/.local/bin."
    export PATH="$HOME/.local/bin:$PATH"
fi
echo "✅ uv installed."

# --- yt-dlp Installation ---
echo "Installing yt-dlp using uv..."
uv tool install yt-dlp
echo "✅ yt-dlp installed."

# --- FZF (Fuzzy Finder) Installation ---
echo "Installing fzf..."
if [[ ! -d ~/.fzf ]]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  # Install fzf keybindings and completion.
  # The install script should handle adding to PATH or user can source it.
  ~/.fzf/install --all
else
  echo "fzf already installed. Skipping."
fi
echo "✅ fzf installed."

# --- Neovim Installation (Pre-compiled Binary) ---
echo "Installing Neovim..."
# Using a recent stable release v0.9.5. Adjust version if needed.
NEOVIM_VERSION="v0.9.5"
NVIM_ARCH="linux64" # Assumes x86_64 Linux. Adjust if target architecture differs.
NVIM_TARBALL="nvim-${NVIM_ARCH}.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${NVIM_TARBALL}"
NVIM_INSTALL_DIR="$HOME/.local/nvim"

# Download and extract Neovim
if [[ ! -f "$HOME/.local/bin/nvim" ]]; then
  echo "Downloading Neovim ${NEOVIM_VERSION} from ${NVIM_URL}..."
  curl -sSL "$NVIM_URL" -o "/tmp/${NVIM_TARBALL}"
  echo "Extracting Neovim..."
  # Remove any previous local Neovim installation directory to ensure clean install
  if [[ -d "$NVIM_INSTALL_DIR" ]]; then
      echo "Removing old Neovim installation directory at $NVIM_INSTALL_DIR..."
      rm -rf "$NVIM_INSTALL_DIR"
  fi
  mkdir -p "$NVIM_INSTALL_DIR"
  # Extract contents, stripping the top-level directory from the tarball
  tar -xzf "/tmp/${NVIM_TARBALL}" -C "$NVIM_INSTALL_DIR" --strip-components=1
  rm "/tmp/${NVIM_TARBALL}"

  # Symlink the nvim binary to $HOME/.local/bin
  if [[ -f "$NVIM_INSTALL_DIR/bin/nvim" ]]; then
      ln -sf "$NVIM_INSTALL_DIR/bin/nvim" "$HOME/.local/bin/nvim"
      echo "✅ Neovim installed to $NVIM_INSTALL_DIR and symlinked to $HOME/.local/bin/nvim."
  else
      echo "Error: Could not find nvim binary after extraction in $NVIM_INSTALL_DIR/bin."
      exit 1
  fi
else
  echo "Neovim binary already exists in $HOME/.local/bin. Skipping."
fi

echo "✅ Labserver setup complete!"
echo "Please ensure your shell's PATH includes $HOME/.local/bin."
echo "You may need to restart your shell or run 'source ~/.zshrc' (or your shell's equivalent)."
