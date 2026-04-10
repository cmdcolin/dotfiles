#!/bin/bash
# A minimal, idempotent dotfile linker (Stow-like) with machine-specific support.
# Usage: ./link.sh [mac|ubuntu|labserver]

set -e

# Show help
show_help() {
    cat << 'EOF'
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
        -h|--help)
            show_help
            exit 0
            ;;
        mac|ubuntu|labserver)
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
SKIP=("hosts" "img" "OLD" "plugin" ".git")

# Function to link a file
link_file() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ]; then
        echo "⚠️  Source not found: $src (skipping)"
        return
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "$dest")"

    # Backup if it's a real file (not a symlink)
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "📦 Backing up existing file: $dest -> $dest.bak"
        mv "$dest" "$dest.bak"
    fi

    # Create symlink (force and verbose)
    ln -sfv "$src" "$dest"
}

# Function to link a package (directory)
link_package() {
    local pkg_path="${1%/}"
    if [ ! -d "$pkg_path" ]; then
        return
    fi

    echo "--- Linking Package: $(basename "$pkg_path") ---"
    # Recursively find all files in the package and link them relative to HOME
    find "$pkg_path" -type f | while read -r src; do
        rel_path="${src#$pkg_path/}"
        dest="$HOME_DIR/$rel_path"
        link_file "$src" "$dest"
    done
}

# 1. Link Common Packages
for pkg in "$DOTFILES_DIR"/*/; do
    pkg_name=$(basename "$pkg")
    
    # Check if pkg_name is in SKIP array
    is_skip=0
    for s in "${SKIP[@]}"; do
        if [[ "$pkg_name" == "$s" ]]; then
            is_skip=1
            break
        fi
    done

    if [ "$is_skip" -eq 0 ]; then
        link_package "$pkg"
    fi
done

# 2. Link Host Variations (Overrides common ones)
if [ -n "$HOST" ]; then
    if [ -d "$DOTFILES_DIR/hosts/$HOST" ]; then
        echo -e "\n--- Processing Host Variations ($HOST) ---"
        link_package "$DOTFILES_DIR/hosts/$HOST"
    fi
else
    echo -e "\n⚠️  No host specified. Link your host configs with: ./link.sh mac|ubuntu|labserver"
fi

echo -e "\n✅ Done!"
