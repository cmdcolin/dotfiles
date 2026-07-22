#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  # Real file in the way: keep a copy rather than silently losing it.
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mv "$dest" "$dest.bak"
    echo "backed up $dest -> $dest.bak"
  fi
  ln -sfn "$src" "$dest"
  echo "$dest -> $src"
}

for pkg in "$DOTFILES_DIR"/*/; do
  name=$(basename "$pkg")
  [[ "$name" =~ ^(img|OLD)$ ]] && continue

  while IFS= read -r src; do
    link "$src" "$HOME/${src#"$pkg"}"
  done < <(find "$pkg" -type f)
done

# Drop links into this repo whose target is gone (e.g. the deleted hosts/ dir).
while IFS= read -r stale; do
  if [[ "$(readlink "$stale")" == "$DOTFILES_DIR"/* ]]; then
    rm "$stale"
    echo "removed dangling link $stale"
  fi
done < <(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print)

echo "✅ Done!"
