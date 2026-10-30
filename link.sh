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
  # statusline is built, not symlinked — see statusline/install.sh
  [[ "$name" == statusline ]] && continue

  while IFS= read -r src; do
    rel="${src#"$pkg"}"
    # A package mirrors $HOME, so everything it links is a dotfile. Anything
    # else at the package root is tooling that belongs to the package -- setup
    # scripts, the config they read -- and mirroring it would drop it in $HOME.
    [[ "$rel" == .* ]] || continue
    link "$src" "$HOME/$rel"
  done < <(find "$pkg" -type f)
done

# Drop dangling links into this repo. Packages nest their files, so search the
# dirs they link into, not just the top of $HOME.
dangling() { find "$@" -type l ! -exec test -e {} \; -print 2>/dev/null; }
while IFS= read -r stale; do
  if [[ "$(readlink "$stale")" == "$DOTFILES_DIR"/* ]]; then
    rm "$stale"
    echo "removed dangling link $stale"
  fi
done < <(
  dangling "$HOME" -maxdepth 1
  for d in "$HOME"/.config "$HOME"/.local/bin "$HOME"/.claude "$HOME"/.gnupg; do
    [[ -d "$d" ]] && dangling "$d" -maxdepth 3
  done
)

echo "✅ Done!"
