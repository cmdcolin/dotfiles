#!/bin/bash
# Build the statusline and install it into the Claude Code config dir.
#
# Not symlinked by link.sh: this needs compiling, and the config dir varies
# with CLAUDE_CONFIG_DIR. Run it directly.
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if command -v cargo >/dev/null 2>&1; then
  cargo build --release --manifest-path "$DIR/Cargo.toml"
  install -Dm755 "$DIR/target/release/statusline" "$CFG/bin/statusline"
  command="$CFG/bin/statusline"
else
  echo "No cargo found — installing the Node fallback instead (~20x slower)."
  command="node $CFG/statusline.cjs"
fi

# Always install the Node build too; it is the fallback on machines without a
# Rust toolchain, and test.sh diffs the two.
install -Dm644 "$DIR/statusline.cjs" "$CFG/statusline.cjs"

echo
echo "Installed to $CFG. Add to $CFG/settings.json:"
echo
echo "  \"statusLine\": { \"type\": \"command\", \"command\": \"$command\" }"
echo
echo "This script deliberately does not edit settings.json for you."
echo "If cache-ttl-statusline@claude-statusline-widgets is installed, disable it:"
echo "its SessionStart hook rewrites statusLine.command back to itself on every"
echo "startup, silently reverting the setting above."
echo
echo "  \"enabledPlugins\": { \"cache-ttl-statusline@claude-statusline-widgets\": false }"
