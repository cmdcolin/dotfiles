# statusline

Claude Code statusline:
`profile | model | context | cost + burn rate | cache expiry | rate-limit windows`.

```
claude2 | Opus 5 1M | 104k/1M 10% | $1.23 $4.60/h | cache 59m (4:21) | 7d 79% 3d11h
```

Replaces the `cache-ttl-statusline` plugin, which spent ~1200 ms per render
(2.7 MB JS bundle re-parsed every time, plus a full transcript parse — and
transcripts reach 40 MB). With several Claude sessions sharing a machine that
cost was multiplied per session, which is what pinned a core.

| | 44 KB transcript | 42 MB transcript |
|---|---|---|
| old plugin | 1237 ms | 1166 ms |
| Node fallback | 21 ms | 38 ms |
| Rust | 0.9 ms | 0.9 ms |

## Install

```sh
./install.sh
```

Builds and installs to `$CLAUDE_CONFIG_DIR` (default `~/.claude`), then prints
the `settings.json` snippet. It does not edit settings.json itself.

`install.sh` is not run by `link.sh` — this needs compiling rather than
symlinking, so `statusline` is in link.sh's exclusion list alongside `plugin`.

## Fields

- **profile** — the `CLAUDE_CONFIG_DIR` basename with its dot stripped, so
  parallel configs (`~/.claude`, `~/.claude2`) are told apart at a glance.
- **context** — green/yellow/red at 65% / 85%. The window is 1M when the model
  id carries `[1m]`, else 200k; if measured usage exceeds that, 1M is assumed
  anyway.
- **burn rate** — cost per wall-clock hour, hidden below a minute where the
  division is meaningless. Prefers `cost.total_duration_ms`, but the harness is
  not confirmed to send it, so it falls back to the transcript's own
  first-to-last timestamp span. That fallback measures elapsed time, so idling
  lowers the rate and a resumed session counts the gap since it started.
- **cache** — countdown and wall-clock expiry, from whichever
  `ephemeral_{1h,5m}_input_tokens` bucket the session actually used.
- **rate-limit windows** — `5h` and `7d` plan utilisation with a countdown to
  the reset, coloured on the same 65% / 85% scale. Each is hidden below 50%,
  where it is only taking up width.

No cwd or git branch, deliberately — that would add a subprocess per render.

## Rate-limit windows

Every other field is computed from stdin and the transcript. These two are not:
utilisation exists only behind `api.anthropic.com/api/oauth/usage`, so it cannot
be read in the render path.

The renderer therefore only ever reads a cache file
(`$TMPDIR/claude-statusline-usage-<profile>.json`, ~2 KB). When that file is
older than five minutes it forks a detached `curl` to rewrite it and renders the
stale copy in the meantime. Cost is one `stat` plus a small parse — measured at
+111 µs against a 33 MB transcript, 653 µs -> 764 µs.

Staleness is mostly harmless by construction: the countdown is derived locally
from the cached `resets_at`, so it stays exact no matter how old the fetch is.
Only the percentage ages, and a five-minute-old percentage is fine for a window
that spans five hours.

Details that are easy to get wrong:

- **The cache is per profile.** Separate config dirs can be separate accounts,
  so a shared cache would show one account's usage under the other's name.
- **Concurrent sessions do not stampede.** The refresh is guarded by an
  `O_EXCL` lock file, taken over only if a previous refresh died holding it —
  this machine runs several sessions at once, each rendering constantly.
- **The token never reaches argv.** Credentials are read inside the forked
  shell (file, then the macOS keychain) and passed to `curl` through the
  environment, where `ps` will not show it.
- **The write is atomic** — fetch to a temp file, then `mv` — so a render can
  never see a half-written cache.

`CLAUDE_STATUSLINE_USAGE_CACHE` overrides the cache path and
`CLAUDE_STATUSLINE_NO_REFRESH` disables the fetch outright; `test.sh` sets both,
because the suite must never touch the network or real credentials.

## Tests

```sh
cargo build --release && ./test.sh
```

37 cases over generated fixtures. Asserts the Rust and Node builds render
byte-identically, and covers what is easy to get wrong: sidechain skipping,
read-window widening, TTL inherited from an older turn, the 200k->1M promotion,
both burn-rate sources, and the usage windows either side of their threshold —
including a stale cache, a corrupt one, and a reset that has already passed.
Fixtures are synthesised per run so the suite does not rot when real sessions
are deleted.

## Notes

Transcripts reach tens of MB, so the newest usage record is found by seeking
64 KB from the end and walking backwards, widening to 1 MB then 8 MB only if
nothing is found. That is why the 42 MB case costs no more than the 44 KB one.

Sidechain (subagent) entries are skipped — their token counts belong to the
subagent's context window, not the main thread's, so including them makes the
meter lurch whenever an agent is spawned.

`statusline.cjs` is a dependency-free Node implementation kept as a fallback for
machines without a Rust toolchain. Output is byte-identical; it is slower only
because Node's interpreter startup (~18 ms) dominates. **If you change one,
change both** — `test.sh` fails if they diverge.
