# statusline

Claude Code statusline: `model | context | cost + burn rate | cache expiry`.

```
Opus 5 1M | 104k/1M 10% | $1.23 $4.60/h | cache 59m (4:21)
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

No cwd or git branch, deliberately — that would add a subprocess per render.

## Tests

```sh
cargo build --release && ./test.sh
```

25 cases over generated fixtures. Asserts the Rust and Node builds render
byte-identically, and covers what is easy to get wrong: sidechain skipping,
read-window widening, TTL inherited from an older turn, the 200k->1M promotion,
and both burn-rate sources. Fixtures are synthesised per run so the suite does
not rot when real sessions are deleted.

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
