#!/usr/bin/env bash
# Parity + behaviour tests for the statusline.
#
# The Rust binary and the Node fallback must render byte-identically. Payloads
# are synthesised here rather than captured from real sessions, so the suite is
# deterministic and does not rot when sessions are deleted.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

RS=${RS:-./target/release/statusline}
CJS=${CJS:-./statusline.cjs}
FIX=$(mktemp -d)
trap 'rm -rf "$FIX"' EXIT

# Pin the profile so the label is not the tester's own config dir.
export CLAUDE_CONFIG_DIR="$FIX/.claude-test"

[ -x "$RS" ] || {
  echo "no binary at $RS — run: cargo build --release"
  exit 1
}

pass=0 fail=0
plain() { sed 's/\x1b\[[0-9]*m//g'; }

# Compares Rust vs Node, then asserts the rendered text contains $2 — or, when
# $2 is prefixed with '!', that it does not. A minute boundary can tick between
# the two runs, so a mismatch is retried once before it is called a failure.
check() {
  local name=$1 want=$2 json=$3 a b
  a=$(printf '%s' "$json" | "$RS")
  b=$(printf '%s' "$json" | node "$CJS")
  if [ "$a" != "$b" ]; then
    a=$(printf '%s' "$json" | "$RS")
    b=$(printf '%s' "$json" | node "$CJS")
  fi
  local text
  text=$(printf '%s' "$a" | plain)
  if [ "$a" != "$b" ]; then
    fail=$((fail + 1))
    printf '  FAIL  %-26s rust/node differ\n          rust: %s\n          node: %s\n' \
      "$name" "$text" "$(printf '%s' "$b" | plain)"
  elif [ "${want#!}" != "$want" ] && [[ "$text" == *"${want#!}"* ]]; then
    fail=$((fail + 1))
    printf '  FAIL  %-26s unwanted %-14s got: %s\n' "$name" "'${want#!}'" "$text"
  elif [ -n "$want" ] && [ "${want#!}" = "$want" ] && [[ "$text" != *"$want"* ]]; then
    fail=$((fail + 1))
    printf '  FAIL  %-26s want %-18s got: %s\n' "$name" "'$want'" "$text"
  else
    pass=$((pass + 1))
    printf '  ok    %-26s %s\n' "$name" "$text"
  fi
}

# Seconds-from-now as a unix timestamp, which is how the harness sends every
# deadline in the payload.
at() { MIN=$1 node -e 'process.stdout.write(String(Math.floor(Date.now()/1000) + Number(process.env.MIN) * 60))'; }

# The shape the harness sends, with the pieces each case varies plugged in.
# <id> <display> <used> <size> <cost> [duration_ms] [cache expiry mins] [cwd]
payload() {
  local extra=""
  [ -n "${6:-}" ] && extra=",\"total_duration_ms\":$6"
  local cache="" cwd=""
  [ -n "${7:-}" ] && cache=",\"prompt_cache\":{\"ttl\":\"1h\",\"expires_at\":$(at "$7")}"
  [ -n "${8:-}" ] && cwd=",\"cwd\":\"$8\""
  printf '{"model":{"id":"%s","display_name":"%s"},"context_window":{"total_input_tokens":%s,"total_output_tokens":0,"context_window_size":%s},"cost":{"total_cost_usd":%s%s}%s%s}' \
    "$1" "$2" "$3" "$4" "$5" "$extra" "$cache" "$cwd"
}

# --- fixtures -------------------------------------------------------------
# git fixtures: HEAD files are hand-written, not from a real `git init`, since
# the renderer only ever reads them and never shells out.
mkdir -p "$FIX/repo/.git" "$FIX/repo/sub/sub2" "$FIX/nogit" "$FIX/detached/.git"
printf 'ref: refs/heads/main\n' >"$FIX/repo/.git/HEAD"
printf 'abcdef1234567890abcdef1234567890abcdef12\n' >"$FIX/detached/.git/HEAD"

# linked worktree: a `.git` file pointing at the main repo's
# `.git/worktrees/<name>`, which holds its own HEAD.
mkdir -p "$FIX/repo/.git/worktrees/feature" "$FIX/worktree"
printf 'ref: refs/heads/feature-branch\n' >"$FIX/repo/.git/worktrees/feature/HEAD"
printf 'gitdir: %s/repo/.git/worktrees/feature\n' "$FIX" >"$FIX/worktree/.git"

# session registry: the harness writes one <pid>.json per live session, and the
# peer name in it is the address SendMessage uses.
mkdir -p "$CLAUDE_CONFIG_DIR/sessions"
session_entry() { # <pid> <sessionId> <name>
  printf '{"pid":%s,"sessionId":"%s","name":"%s","cwd":"%s"}' "$1" "$2" "$3" "$FIX/repo" \
    >"$CLAUDE_CONFIG_DIR/sessions/$1.json"
}
session_entry 111 aaaa-1111 repo-4f
session_entry 222 bbbb-2222 reviewer
# a stray non-json file in the dir must not derail the scan
printf 'not json\n' >"$CLAUDE_CONFIG_DIR/sessions/111.key"

# --- context window -------------------------------------------------------
O='claude-opus-5[1m]'
D='Opus 5 (1M context)'
M=1000000
K=200000
check "1m window" "50k/1M 5%" "$(payload "$O" "$D" 50000 $M 1.2345)"
check "200k window" "50k/200k 25%" "$(payload 'claude-opus-5' 'Opus 5' 50000 $K 0.07)"
# The size is the harness's own, so a model whose name advertises nothing still
# gets the right ceiling -- the old id/display-name sniffing could not.
check "size not sniffed" "500k/1M 50%" "$(payload 'claude-fable-5-1' 'Fable 5.1' 500000 $M 1)"
check "high context" "900k/1M 90%" "$(payload "$O" "$D" 900000 $M 1)"
check "empty window" "0/1M 0%" "$(payload "$O" "$D" 0 $M 1)"
check "model suffix" "Opus 5 1M" "$(payload "$O" "$D" 50000 $M 1)"
# A zero or missing size would divide by zero; the field is simply dropped.
check "zero size" "!/0" "$(payload "$O" "$D" 50000 0 1)"
check "no window field" '$1.50' '{"model":{"id":"'"$O"'"},"cost":{"total_cost_usd":1.5}}'
check "no model field" "50k/1M" '{"context_window":{"total_input_tokens":50000,"total_output_tokens":0,"context_window_size":1000000}}'
# Output rolls into the next request, so it counts toward the window.
check "output counted" "60k/1M 6%" '{"context_window":{"total_input_tokens":50000,"total_output_tokens":10000,"context_window_size":1000000}}'

# --- cost + burn rate -----------------------------------------------------
check "cost rounding" '$1.23' "$(payload "$O" "$D" 50000 $M 1.2345)"
check "zero cost" '$0.00' "$(payload "$O" "$D" 50000 $M 0)"
# burn rate: cost / wall-clock hours. 1.2345 over 7.5 min = $9.88/h.
check "burn rate" '$9.88/h' "$(payload "$O" "$D" 50000 $M 1.2345 450000)"
check "burn rate >=10" '$100/h' "$(payload "$O" "$D" 50000 $M 100 3600000)"
check "burn under 1min" '!/h' "$(payload "$O" "$D" 50000 $M 1 30000)"
check "burn no duration" '!/h' "$(payload "$O" "$D" 50000 $M 1)"
check "no cost field" "50k/1M" '{"context_window":{"total_input_tokens":50000,"total_output_tokens":0,"context_window_size":1000000}}'

# --- effort ---------------------------------------------------------------
effort_payload() {
  printf '{"model":{"id":"%s","display_name":"%s"},"cost":{"total_cost_usd":1},"effort":{"level":"%s"}}' "$O" "$D" "$1"
}
check "effort low" "low" "$(effort_payload low)"
check "effort high" "high" "$(effort_payload high)"
check "effort xhigh" "xhigh" "$(effort_payload xhigh)"

# --- prompt cache ---------------------------------------------------------
check "cache countdown" "cache 59m" "$(payload "$O" "$D" 50000 $M 1 "" 60)"
check "cache near expiry" "cache 2m" "$(payload "$O" "$D" 50000 $M 1 "" 3)"
check "cache expired" "cache expired" "$(payload "$O" "$D" 50000 $M 1 "" -5)"
# Absent before the session has written a cache block: no field, no placeholder.
check "cache absent" "!cache" "$(payload "$O" "$D" 50000 $M 1)"

# --- worktree + peer name -------------------------------------------------
check "worktree name" "repo" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/repo")"
check "worktree nested" "repo" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/repo/sub/sub2")"
check "worktree linked" "worktree" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/worktree")"
check "no worktree name" "!repo" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/nogit")"

# The address other sessions message this one by. It opens with the project
# basename, so it replaces the worktree field instead of repeating it.
peer_payload() { # sessionId
  printf '{"model":{"id":"%s","display_name":"%s"},"cost":{"total_cost_usd":1},"cwd":"%s","session_id":"%s"}' \
    "$O" "$D" "$FIX/repo" "$1"
}
check "peer name" "claude-test | repo-4f |" "$(peer_payload aaaa-1111)"
check "peer name absorbs wt" "!repo | repo-4f" "$(peer_payload aaaa-1111)"
check "renamed peer keeps wt" "repo | reviewer |" "$(peer_payload bbbb-2222)"
check "unknown session id" "claude-test | repo |" "$(peer_payload cccc-3333)"
check "no session id" "claude-test | repo |" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/repo")"

# --- git branch -----------------------------------------------------------
check "git branch" "main" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/repo")"
check "git branch nested" "main" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/repo/sub/sub2")"
check "git branch worktree" "feature-branch" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/worktree")"
check "git branch detached" "abcdef1" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/detached")"
check "no git repo" "!main" "$(payload "$O" "$D" 50000 $M 1 "" "" "$FIX/nogit")"
check "no cwd" "!main" "$(payload "$O" "$D" 50000 $M 1)"

# --- degenerate input -----------------------------------------------------
check "profile label" "claude-test |" "$(payload "$O" "$D" 50000 $M 1)"
check "empty object" "" '{}'
check "malformed json" "" 'not json at all'
check "empty stdin" "" ''

# --- rate-limit windows ---------------------------------------------------
# <5h pct> <5h reset mins> <7d pct> <7d reset mins>; an empty pct drops the
# window entirely, which is how the harness sends a session with no plan data.
limits() {
  printf '{"model":{"id":"%s","display_name":"%s"},"cost":{"total_cost_usd":1},"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%s},"seven_day":{"used_percentage":%s,"resets_at":%s}}}' \
    "$O" "$D" "$1" "$(at "$2")" "$3" "$(at "$4")"
}

# Both windows under the threshold stay hidden — the common case, and the
# reason the line does not grow for a session that is nowhere near a limit.
check "usage below thresh" "!5h" "$(limits 3 110 20 4320)"
check "5h shown" "5h 62% 1h49m" "$(limits 62 110 20 4320)"
check "7d shown" "7d 79% 2d" "$(limits 3 110 79 4320)"
check "both shown" "5h 91%" "$(limits 91 110 88 4320)"
check "both shown 7d" "7d 88%" "$(limits 91 110 88 4320)"
# Under an hour the countdown drops the hours component entirely. Asserted one
# minute short: the countdown floors, and a deadline minted "47 minutes out" is
# a hair under that by the time it renders.
check "5h minutes only" "5h 62% 46m" "$(limits 62 47 20 4320)"
# A window past its reset keeps the percentage but drops the countdown, which
# would otherwise render as a negative duration.
check "5h reset passed" "5h 62%" "$(limits 62 -5 79 4320)"
check "5h reset passed 7d" "7d 79% 2d23h" "$(limits 62 -5 79 4320)"
check "no rate_limits" "!5h" "$(payload "$O" "$D" 50000 $M 1)"
check "null window" "!5h" '{"cost":{"total_cost_usd":1},"rate_limits":{"five_hour":null,"seven_day":{}}}'
check "no reset field" "5h 62%" '{"cost":{"total_cost_usd":1},"rate_limits":{"five_hour":{"used_percentage":62},"seven_day":null}}'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
