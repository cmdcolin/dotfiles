#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  mkdir -p "$(dirname "$2")"
  ln -sfv "$1" "$2"
}

for pkg in "$DOTFILES_DIR"/*/; do
  name=$(basename "$pkg")
  [[ "$name" =~ ^(img|OLD|.git|plugin)$ ]] && continue

  find "$pkg" -type f | while read -r src; do
    dest="$HOME/${src#$pkg}"
    link "$src" "$dest"
  done
done

echo "✅ Done!"
