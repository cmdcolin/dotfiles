#!/usr/bin/env bash
# Parity + behaviour tests for the statusline.
#
# The Rust binary and the Node fallback must render byte-identically. Fixtures
# are synthesised here rather than read from real transcripts, so the suite is
# deterministic and does not rot when sessions are deleted.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

RS=${RS:-./target/release/statusline}
CJS=${CJS:-./statusline.cjs}
FIX=$(mktemp -d)
trap 'rm -rf "$FIX"' EXIT

[ -x "$RS" ] || {
  echo "no binary at $RS — run: cargo build --release"
  exit 1
}

pass=0 fail=0
plain() { sed 's/\x1b\[[0-9]*m//g'; }

# usage line: <sidechain> <ts> <cache_creation> <cache_read> <1h?>
line() {
  printf '{"isSidechain":%s,"type":"assistant","timestamp":"%s","message":{"usage":{"input_tokens":2,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":100,"cache_creation":{"ephemeral_1h_input_tokens":%s,"ephemeral_5m_input_tokens":%s}}}}\n' \
    "$1" "$2" "$3" "$4" "$([ "$5" = 1h ] && echo "$3" || echo 0)" "$([ "$5" = 5m ] && echo "$3" || echo 0)"
}

payload() { # transcript id display cost [duration_ms]
  if [ -n "${5:-}" ]; then
    printf '{"transcript_path":"%s","model":{"id":"%s","display_name":"%s"},"cost":{"total_cost_usd":%s,"total_duration_ms":%s}}' "$@"
  else
    printf '{"transcript_path":"%s","model":{"id":"%s","display_name":"%s"},"cost":{"total_cost_usd":%s}}' "$1" "$2" "$3" "$4"
  fi
}

# Compares Rust vs Node, then asserts the rendered text contains $2.
# A minute boundary can tick between the two runs, so a mismatch is retried
# once before it is called a failure.
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
  elif [ -n "$want" ] && [[ "$text" != *"$want"* ]]; then
    fail=$((fail + 1))
    printf '  FAIL  %-26s want %-18s got: %s\n' "$name" "'$want'" "$text"
  else
    pass=$((pass + 1))
    printf '  ok    %-26s %s\n' "$name" "$text"
  fi
}

# Minute offsets via node, not `date -d` / `stat -c`: those are GNU-only and
# absent on macOS, while node is already required for the parity check. The
# offset goes through the environment because node reads a leading-dash argv
# entry like -180 as one of its own CLI options.
now_iso() { OFFSET_MIN=$1 node -e 'process.stdout.write(new Date(Date.now() + Number(process.env.OFFSET_MIN) * 60000).toISOString())'; }
filesize() { wc -c <"$1" | tr -d ' '; }

# --- fixtures -------------------------------------------------------------
line false "$(now_iso 0)" 1000 48898 1h >"$FIX/basic.jsonl"
line false "$(now_iso 0)" 1000 48898 5m >"$FIX/ttl5m.jsonl"
line false "$(now_iso -180)" 1000 48898 1h >"$FIX/expired.jsonl"
line false "$(now_iso 0)" 5000 894898 1h >"$FIX/huge.jsonl"

# main thread at ~50k, then a subagent at ~900k: must report the main thread.
{
  line false "$(now_iso 0)" 1000 48898 1h
  line true "$(now_iso 0)" 5000 894898 1h
} >"$FIX/sidechain.jsonl"

# usage record sits >64KB from EOF, forcing the read window to widen.
{
  line false "$(now_iso 0)" 1000 48898 1h
  for _ in $(seq 900); do printf '{"type":"user","pad":"%0100d"}\n' 0; done
} >"$FIX/farback.jsonl"

# 30-minute span with no total_duration_ms: burn rate must come from the
# transcript's own first->last timestamps, so cost/0.5h == 2x cost.
{
  line false "$(now_iso -30)" 1000 20000 1h
  line false "$(now_iso 0)" 1000 48898 1h
} >"$FIX/span.jsonl"

# newest turn created no cache blocks; TTL must come from an older turn.
{
  line false "$(now_iso -2)" 1000 48898 1h
  line false "$(now_iso 0)" 0 49898 none
} >"$FIX/nocreate.jsonl"

farback_size=$(filesize "$FIX/farback.jsonl")
echo "fixture sizes: farback=$farback_size bytes (window widening $([ "$farback_size" -gt 65536 ] && echo exercised || echo 'NOT exercised'))"
echo

# --- cases ----------------------------------------------------------------
O='claude-opus-5[1m]'
D='Opus 5 (1M context)'
check "1m window" "50k/1M" "$(payload "$FIX/basic.jsonl" "$O" "$D" 1.2345)"
check "cost rounding" '$1.23' "$(payload "$FIX/basic.jsonl" "$O" "$D" 1.2345)"
check "model suffix" "Opus 5 1M" "$(payload "$FIX/basic.jsonl" "$O" "$D" 1)"
check "200k window" "50k/200k" "$(payload "$FIX/basic.jsonl" 'claude-opus-5' 'Opus 5' 0.07)"
check "-1m id" "50k/1M" "$(payload "$FIX/basic.jsonl" 'claude-opus-5-1m' 'Opus 5' 1)"
check "over-200k promo" "/1M" "$(payload "$FIX/huge.jsonl" 'claude-opus-5' 'Opus 5' 9.99)"
check "5m ttl" "cache" "$(payload "$FIX/ttl5m.jsonl" "$O" "$D" 1)"
check "expired cache" "cache expired" "$(payload "$FIX/expired.jsonl" "$O" "$D" 1)"
check "sidechain skip" "50k/1M" "$(payload "$FIX/sidechain.jsonl" "$O" "$D" 1)"
check "window widening" "50k/1M" "$(payload "$FIX/farback.jsonl" "$O" "$D" 1)"
check "ttl from older" "cache" "$(payload "$FIX/nocreate.jsonl" "$O" "$D" 1)"
check "high context" "900k/1M 90%" "$(payload "$FIX/huge.jsonl" "$O" "$D" 1)"
# burn rate: cost / wall-clock hours. 1.2345 over 7.5 min = $9.88/h.
check "burn rate" '$9.88/h' "$(payload "$FIX/basic.jsonl" "$O" "$D" 1.2345 450000)"
check "burn rate >=10" '$100/h' "$(payload "$FIX/basic.jsonl" "$O" "$D" 100 3600000)"
check "burn under 1min" '$1.00 |' "$(payload "$FIX/basic.jsonl" "$O" "$D" 1 30000)"
# no duration field: derived from the transcript span instead.
check "burn from span" '$8.00/h' "$(payload "$FIX/span.jsonl" "$O" "$D" 4)"
# 4h duration beats the 30min span ($8.00/h) -> proves the field takes priority.
check "duration wins" '$1.00/h' "$(payload "$FIX/span.jsonl" "$O" "$D" 4 14400000)"
check "single-line span" '$1.00 |' "$(payload "$FIX/basic.jsonl" "$O" "$D" 1)"
check "missing file" '$0.50' "$(payload "/nope.jsonl" "$O" "$D" 0.5)"
check "zero cost" '$0.00' "$(payload "$FIX/basic.jsonl" "$O" "$D" 0)"
check "no cost field" "50k/1M" '{"transcript_path":"'"$FIX/basic.jsonl"'","model":{"id":"'"$O"'","display_name":"'"$D"'"}}'
check "no model field" '$1.50' '{"transcript_path":"'"$FIX/basic.jsonl"'","cost":{"total_cost_usd":1.5}}'
check "empty object" "" '{}'
check "malformed json" "" 'not json at all'
check "empty stdin" "" ''

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
