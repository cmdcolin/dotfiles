#!/bin/bash
# Build the statusline into ~/.local/bin, shared by every Claude profile: the
# binary reads its profile from CLAUDE_CONFIG_DIR, not from where it lives.
#
# Not symlinked by link.sh: this needs compiling. Run it directly.
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/statusline"

# BSD install (macOS) has no -D, so create the directories separately.
mkdir -p "$BIN" "$SHARE"

if command -v cargo >/dev/null 2>&1; then
  cargo build --release --manifest-path "$DIR/Cargo.toml"
  install -m755 "$DIR/target/release/statusline" "$BIN/statusline"
  command="$BIN/statusline"
else
  echo "No cargo found — installing the Node fallback instead (~20x slower)." >&2
  rm -f "$BIN/statusline"
  command="node $SHARE/statusline.cjs"
fi

# The Node build is the fallback on machines without a Rust toolchain, and
# test.sh diffs the two.
install -m644 "$DIR/statusline.cjs" "$SHARE/statusline.cjs"

echo "$command"
