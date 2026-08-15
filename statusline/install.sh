#!/bin/bash
# Build the statusline and install it into the Claude Code config dir.
#
# Not symlinked by link.sh: this needs compiling, and the config dir varies
# with CLAUDE_CONFIG_DIR. Run it directly.
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# BSD install (macOS) has no -D, so create the directories separately.
mkdir -p "$CFG/bin"

if command -v cargo >/dev/null 2>&1; then
  cargo build --release --manifest-path "$DIR/Cargo.toml"
  install -m755 "$DIR/target/release/statusline" "$CFG/bin/statusline"
  command="$CFG/bin/statusline"
else
  echo "No cargo found — installing the Node fallback instead (~20x slower)."
  command="node $CFG/statusline.cjs"
fi

# Always install the Node build too; it is the fallback on machines without a
# Rust toolchain, and test.sh diffs the two.
install -m644 "$DIR/statusline.cjs" "$CFG/statusline.cjs"

# Both builds fork this for the usage windows. Without it they render every
# other field and simply omit those two.
install -m755 "$DIR/refresh.sh" "$CFG/refresh.sh"

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
