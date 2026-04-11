#!/bin/bash
set -e

HOST="${1:-ubuntu}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  mkdir -p "$(dirname "$2")"
  ln -sfv "$1" "$2"
}

echo "--- Linking Common ---"
for pkg in "$DOTFILES_DIR"/*/; do
  name=$(basename "$pkg")
  [[ "$name" =~ ^(hosts|img|OLD|.git|plugin)$ ]] && continue

  find "$pkg" -type f | while read -r src; do
    dest="$HOME/${src#$pkg}"
    link "$src" "$dest"
  done
done

if [[ -d "$DOTFILES_DIR/hosts/$HOST" ]]; then
  echo -e "\n--- Linking Host: $HOST ---"
  find "$DOTFILES_DIR/hosts/$HOST" -type f | while read -r src; do
    name=$(basename "$src")
    # Skip base config files in host dir; they should use .local overrides
    [[ "$name" =~ ^(\.zshrc|\.tmux\.conf)$ ]] && continue
    dest="$HOME/${src#$DOTFILES_DIR/hosts/$HOST/}"
    link "$src" "$dest"
  done
fi

echo -e "\n✅ Done!"
