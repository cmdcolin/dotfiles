# statusline

Claude Code statusline:
`profile | branch | model | context | cost + burn rate | cache expiry | rate-limit windows`.

```
claude2 | main | Opus 5 1M | 104k/1M 10% | $1.23 $4.60/h | cache 59m (4:21) | 7d 79% 3d11h
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
The repo's top-level `install.sh` runs it once per profile through
`claude/sync-profiles.sh`, which also writes the `statusLine` setting.

## Fields

- **profile** — the `CLAUDE_CONFIG_DIR` basename with its dot stripped, so
  parallel configs (`~/.claude`, `~/.claude2`) are told apart at a glance.
- **branch** — read straight from `.git/HEAD` under `cwd` (walking up to find
  it, and following a worktree/submodule's `gitdir:` redirect), never a `git`
  subprocess. Detached HEAD shows a short hash. Absent outside a git repo.
- **context** — green/yellow/red at 65% / 85%. The window is 1M when the model
  id carries `[1m]` or the display name ends in `(1M context)`, else 200k. If
  measured usage exceeds the assumed window, 1M is assumed anyway — the count
  is itself proof the window is bigger, since the API would have rejected the
  request otherwise.
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

No cwd, deliberately — it would add little over the branch name and this
already reads `.git/HEAD` for that. The branch itself costs a handful of
`stat`/`read` calls, not a `git` subprocess — see below.

## Rate-limit windows

Every other field is computed from stdin and the transcript. These two are not:
utilisation exists only behind `api.anthropic.com/api/oauth/usage`, so it cannot
be read in the render path.

The renderer therefore only ever reads a cache file
(`$TMPDIR/claude-statusline-usage-<profile>.json`, ~2 KB). When that file is
older than its backoff allows it forks `refresh.sh` detached to rewrite it, and
renders the stale copy in the meantime. Cost is one `stat` plus a small parse —
measured at +111 µs against a 33 MB transcript, 653 µs -> 764 µs.

`refresh.sh` is a real file, installed to `$CLAUDE_CONFIG_DIR` beside the
builds, rather than a string literal inside each of them: embedded, it existed
twice under two sets of escaping rules, could drift, and `shellcheck` could not
see it. Both builds fork the same copy, and the suite runs the checkout's.
`CLAUDE_STATUSLINE_REFRESH` overrides the path. If it is missing, the two
windows simply do not render and every other field is unaffected.

A pure-Rust fetch was considered and rejected: `ureq` + `rustls` takes the
binary from 508 KB to 2.0 MB and the tree from 11 crates to 127, and it would
not remove the duplication anyway — `statusline.cjs` cannot call the binary, so
it would need its own implementation, leaving two to keep in step instead of
one. The fork is not avoidable either way: the renderer exits as soon as it has
written stdout, so a background thread would be killed mid-flight.

Staleness is mostly harmless by construction: the countdown is derived locally
from the cached `resets_at`, so it stays exact no matter how old the fetch is.
Only the percentage ages, and a five-minute-old percentage is fine for a window
that spans five hours.

Failures back off — 5m, 10m, 20m, 40m, then hourly — counted in a file beside
the cache and cleared on success, so recovery is immediate. The endpoint goes
down often enough that a fixed interval turns an outage into a doomed fork every
few minutes for as long as it lasts. A 200 carrying an error page counts as a
failure too, checked by grepping the body before the atomic `mv`.

Details that are easy to get wrong:

- **The cache is per profile.** Separate config dirs can be separate accounts,
  so a shared cache would show one account's usage under the other's name.
- **Concurrent sessions do not stampede.** The refresh is guarded by an
  `O_EXCL` lock file, taken over only if a previous refresh died holding it —
  this machine runs several sessions at once, each rendering constantly.
- **The token never reaches argv.** Credentials are read inside the forked
  shell (file, then the macOS keychain) and reach `curl` through a `-K` config
  on stdin. A shell-expanded `-H "Authorization: Bearer $TOK"` would put the
  token in `curl`'s argv, which `/proc/PID/cmdline` shows to any local user.
- **A window past its reset is dropped, not frozen.** If the refresh is failing
  — expired token, no `curl`, no network — the cache eventually describes a
  window that has already rolled over. Rendering nothing beats rendering a
  confident `7d 80%` over a window that is actually empty.
- **The write is atomic** — fetch to a temp file, then `mv` — so a render can
  never see a half-written cache.

`CLAUDE_STATUSLINE_USAGE_CACHE` overrides the cache path and
`CLAUDE_STATUSLINE_NO_REFRESH` disables the fetch outright; `test.sh` sets both,
because the suite must never touch the network or real credentials.

## Tests

```sh
cargo build --release && ./test.sh
```

59 cases over generated fixtures. Asserts the Rust and Node builds render
byte-identically, and covers what is easy to get wrong: sidechain skipping,
read-window widening, TTL inherited from an older turn, both 1M signals and the
200k->1M promotion, both burn-rate sources, the usage windows either side of
their threshold — including a stale cache, a corrupt one, and a reset that has
already passed — and git branch resolution: a nested subdirectory, a linked
worktree's `gitdir:` redirect, detached HEAD, and no repo at all. A `want`
prefixed with `!` asserts absence instead. Fixtures are synthesised per run so
the suite does not rot when real sessions are deleted.

The refresh cases are the only ones that fork it for real, so they drop
`CLAUDE_STATUSLINE_NO_REFRESH` and put a stub `curl` on `PATH` with fake
credentials — still no network — covering failure counting, backoff suppressing
a retry, backoff expiry letting exactly one through, an HTML body, success
clearing the counter, and a missing `refresh.sh` leaving no stale lock.

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
