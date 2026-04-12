#!/bin/bash
# A minimal, idempotent dotfile linker (Stow-like) with machine-specific support.
# Usage: ./link.sh [mac|ubuntu|labserver]

set -e

# Show help
show_help() {
  cat <<'EOF'
Usage: ./link.sh [HOST]

Link dotfiles from this repo to your home directory.

HOST (optional):
    mac         Link common configs + macOS overrides
    ubuntu      Link common configs + Ubuntu overrides
    labserver   Link common configs + labserver overrides
    -h, --help  Show this help message

If no HOST is specified, common configs are linked without host overrides.

Examples:
    ./link.sh mac       # Link with macOS-specific configs
    ./link.sh ubuntu    # Link with Ubuntu-specific configs
    ./link.sh           # Link common configs only (no host overrides)
EOF
}

# Parse arguments
HOST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    show_help
    exit 0
    ;;
  mac | ubuntu | labserver)
    HOST="$1"
    shift
    ;;
  *)
    echo "Error: Unknown argument '$1'"
    echo "Run './link.sh --help' for usage"
    exit 1
    ;;
  esac
done

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

# Directories to skip (not dotfile folders)
SKIP=("hosts" "img" "OLD" ".git")

# Function to link a file
link_file() {
  local src="$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    return
  fi

  # Ensure destination directory exists
  mkdir -p "$(dirname "$dest")"

  # Backup if it's a real file (not a symlink)
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    echo "📦 Backing up existing file: $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  # Create symlink
  ln -sfv "$src" "$dest"
}

# Function to link a package (directory)
link_package() {
  local pkg_path="${1%/}"
  echo "--- Linking Package: $(basename "$pkg_path") ---"
  # Recursively find all files in the package and link them relative to HOME
  find "$pkg_path" -type f | while read -r src; do
    rel_path="${src#$pkg_path/}"
    link_file "$src" "$HOME_DIR/$rel_path"
  done
}

# 1. Link Common Packages
for pkg in "$DOTFILES_DIR"/*/; do
  pkg_name=$(basename "$pkg")

  # Check if pkg_name is in SKIP array
  is_skip=0
  for s in "${SKIP[@]}"; do
    [[ "$pkg_name" == "$s" ]] && is_skip=1 && break
  done

  [[ "$is_skip" -eq 0 ]] && link_package "$pkg"
done

# 2. Link Host Variations (Overrides common ones)
# .zshrc and .tmux.conf are handled by the base config + .local override pattern
HOST_SKIP_FILES=(".zshrc" ".tmux.conf")

if [ -n "$HOST" ]; then
  if [ -d "$DOTFILES_DIR/hosts/$HOST" ]; then
    echo -e "\n--- Processing Host Variations ($HOST) ---"
    find "$DOTFILES_DIR/hosts/$HOST" -type f | while read -r src; do
      rel_path="${src#$DOTFILES_DIR/hosts/$HOST/}"
      is_skip=0
      for s in "${HOST_SKIP_FILES[@]}"; do
        if [[ "$rel_path" == "$s" ]]; then
          is_skip=1
          break
        fi
      done
      if [ "$is_skip" -eq 1 ]; then
        echo "  (skipped $rel_path — use .${rel_path}.local for host overrides)"
      else
        link_file "$src" "$HOME_DIR/$rel_path"
      fi
    done
  fi
else
  echo -e "\n⚠️  No host specified. Link your host configs with: ./link.sh mac|ubuntu|labserver"
fi

echo -e "\n✅ Done!"
