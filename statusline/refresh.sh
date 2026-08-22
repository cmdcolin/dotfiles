#!/bin/sh
# Refresh the rate-limit usage cache. Forked detached by the statusline when the
# cache is older than its backoff allows; never run in the render path.
#
# Both builds share this one copy rather than embedding it as a string literal,
# where it existed twice under two sets of escaping rules and could drift.
#
# In:  CACHE  cache file to write
#      LOCK   lock file to release on exit
#      FAIL   consecutive-failure counter the renderer backs off on
set -u
[ -n "${CACHE:-}" ] && [ -n "${LOCK:-}" ] && [ -n "${FAIL:-}" ] || exit 0

trap 'rm -f "$LOCK"' EXIT

# Every exit that leaves the cache unwritten bumps the failure count. Success
# clears it, so recovery from an outage is immediate rather than another wait.
fail() {
  n=$(cat "$FAIL" 2>/dev/null)
  case "$n" in '' | *[!0-9]*) n=0 ;; esac
  echo $((n + 1)) >"$FAIL"
  exit 0
}

token() { grep -o '"accessToken":"[^"]*"' | head -1 | cut -d'"' -f4; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CFG=${CFG%/}

# Every profile but the default keeps its keychain entry under a service name
# suffixed with the first 8 hex of the sha256 of its config dir, so the bare
# name read from ~/.claude2 hands back the default profile's account. There is
# deliberately no fall back to the bare name: no windows at all beats a
# confident percentage belonging to somebody else's account.
service() {
  [ "$CFG" = "$HOME/.claude" ] && { printf 'Claude Code-credentials'; return; }
  if command -v shasum >/dev/null 2>&1; then h=$(printf '%s' "$CFG" | shasum -a 256)
  else h=$(printf '%s' "$CFG" | sha256sum); fi
  printf 'Claude Code-credentials-%s' "$(printf '%s' "$h" | cut -c1-8)"
}

TOK=$(cat "$CFG/.credentials.json" 2>/dev/null | token)
[ -n "$TOK" ] ||
  TOK=$(security find-generic-password -s "$(service)" -w 2>/dev/null | token)
[ -n "$TOK" ] || fail

TMP="$CACHE.$$"

# Through a -K config on stdin, not -H: a shell-expanded header would put the
# token in curl's argv, where /proc/PID/cmdline shows it to any local user.
curl -sf --max-time 10 -K - \
  https://api.anthropic.com/api/oauth/usage -o "$TMP" <<HDR || { rm -f "$TMP"; fail; }
header = "Authorization: Bearer $TOK"
header = "anthropic-beta: oauth-2025-04-20"
HDR

# A 200 carrying an error page or a truncated body would otherwise be cached as
# a success and served for the full TTL.
grep -q '"five_hour"' "$TMP" || { rm -f "$TMP"; fail; }

mv -f "$TMP" "$CACHE"
rm -f "$FAIL"
