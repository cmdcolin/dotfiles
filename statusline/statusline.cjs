#!/usr/bin/env node
// Minimal Claude Code statusline: model | context | cost | cache expiry.
//
// Deliberately dependency-free and tail-reading: transcripts reach tens of MB,
// so we seek the last usage record from the end of the file instead of parsing
// it. Target is a few ms of CPU per render.

const fs = require('fs')
const os = require('os')
const path = require('path')
const { spawn } = require('child_process')

const RESET = '\x1b[0m'
const paint = (code, text) => `\x1b[${code}m${text}${RESET}`
const dim = text => paint(2, text)

const HOUR_MS = 3600_000
const FIVE_MIN_MS = 300_000

// Rate-limit windows move slowly, and the reset countdown is computed locally
// from the cached resets_at, so only the percentage ages between refreshes.
const USAGE_TTL_MS = 300_000
const USAGE_LOCK_STALE_MS = 120_000
// Below this the window is not worth the width; it is the tail that matters.
const USAGE_SHOW_AT_PCT = 50

function readStdin() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'))
  } catch {
    return {}
  }
}

// Walk the tail of the transcript backwards for the newest main-thread usage
// record. Sidechain (subagent) entries are skipped: their token counts belong
// to the subagent's window, not ours, and would make the meter jump around.
function readTail(path) {
  let fd
  try {
    fd = fs.openSync(path, 'r')
  } catch {
    return null
  }
  try {
    const size = fs.fstatSync(fd).size
    for (const window of [64 * 1024, 1024 * 1024, 8 * 1024 * 1024]) {
      const start = Math.max(0, size - window)
      const buf = Buffer.allocUnsafe(size - start)
      fs.readSync(fd, buf, 0, buf.length, start)
      const lines = buf.toString('utf8').split('\n')
      if (start > 0) lines.shift() // partial line, and any split multibyte char

      let latest = null
      let ttlMs = null
      for (let i = lines.length - 1; i >= 0; i--) {
        const line = lines[i]
        if (line.length < 2 || !line.includes('"usage"')) continue
        let entry
        try {
          entry = JSON.parse(line)
        } catch {
          continue
        }
        if (entry.isSidechain) continue
        const usage = entry.message && entry.message.usage
        if (!usage) continue

        if (!latest) latest = { usage, ts: entry.timestamp }

        // Which TTL this session negotiated. The newest turn may have created
        // no cache blocks at all, so keep looking back for a nonzero marker.
        const created = usage.cache_creation
        if (ttlMs === null && created) {
          if (created.ephemeral_1h_input_tokens > 0) ttlMs = HOUR_MS
          else if (created.ephemeral_5m_input_tokens > 0) ttlMs = FIVE_MIN_MS
        }
        if (latest && ttlMs !== null) break
      }
      if (latest) return { ...latest, ttlMs: ttlMs ?? HOUR_MS }
      if (start === 0) break
    }
  } catch {
    /* fall through */
  } finally {
    fs.closeSync(fd)
  }
  return null
}

// Session start, for the burn rate. The harness may or may not send
// cost.total_duration_ms, so fall back to the transcript's own span.
function firstTimestamp(path) {
  let fd
  try {
    fd = fs.openSync(path, 'r')
  } catch {
    return null
  }
  try {
    const buf = Buffer.allocUnsafe(65536)
    const read = fs.readSync(fd, buf, 0, 65536, 0)
    for (const line of buf.subarray(0, read).toString('utf8').split('\n')) {
      if (line.length < 2 || !line.includes('"timestamp"')) continue
      try {
        const entry = JSON.parse(line)
        if (entry.timestamp) return entry.timestamp
      } catch {
        /* truncated tail line */
      }
    }
  } finally {
    fs.closeSync(fd)
  }
  return null
}

function compact(n) {
  const trim = s => (s.includes('.') ? s.replace(/\.?0+$/, '') : s)
  if (n >= 1_000_000) return `${trim((n / 1_000_000).toFixed(2))}M`
  if (n >= 1000) return `${trim((n / 1000).toFixed(n >= 100_000 ? 0 : 1))}k`
  return String(n)
}

function clock(ms) {
  const d = new Date(ms)
  return `${d.getHours() % 12 || 12}:${String(d.getMinutes()).padStart(2, '0')}`
}

// Refresh the usage cache out of band. Credentials are read here rather than
// in the renderer so the macOS keychain fallback costs nothing per render, and
// the token goes through the environment rather than argv, where `ps` would
// show it. The write is atomic so a render never sees a half-written file.
const REFRESH_SH = `
trap 'rm -f "$LOCK"' EXIT
CFG="\${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
token() { grep -o '"accessToken":"[^"]*"' | head -1 | cut -d'"' -f4; }
TOK=$(cat "$CFG/.credentials.json" 2>/dev/null | token)
[ -n "$TOK" ] || TOK=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | token)
[ -n "$TOK" ] || exit 0
TMP="$CACHE.$$"
export TOK
curl -sf --max-time 10 \\
  -H "Authorization: Bearer $TOK" \\
  -H 'anthropic-beta: oauth-2025-04-20' \\
  https://api.anthropic.com/api/oauth/usage -o "$TMP" || { rm -f "$TMP"; exit 0; }
mv -f "$TMP" "$CACHE"
`

const configDir = () =>
  process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude')

// Which config dir this session is running under: .claude2 -> claude2.
function profileLabel() {
  const name = path.basename(configDir()).replace(/^\./, '')
  return name || null
}

function usageCachePath() {
  if (process.env.CLAUDE_STATUSLINE_USAGE_CACHE) {
    return process.env.CLAUDE_STATUSLINE_USAGE_CACHE
  }
  // Per profile: separate config dirs can be separate accounts.
  return path.join(
    os.tmpdir(),
    `claude-statusline-usage-${profileLabel() || 'default'}.json`,
  )
}

function ageMs(file) {
  try {
    return Date.now() - fs.statSync(file).mtimeMs
  } catch {
    return null
  }
}

// Fire-and-forget refresh. The lock keeps concurrent sessions from stampeding
// the endpoint; it is taken over if a previous refresh died holding it.
function spawnRefresh(cache) {
  if (process.env.CLAUDE_STATUSLINE_NO_REFRESH) return
  const lock = path.join(
    path.dirname(cache),
    path.basename(cache, path.extname(cache)) + '.lock',
  )
  const age = ageMs(lock)
  if (age !== null) {
    if (age < USAGE_LOCK_STALE_MS) return
    try {
      fs.unlinkSync(lock)
    } catch {
      /* another render won the race */
    }
  }
  try {
    fs.closeSync(fs.openSync(lock, 'wx'))
  } catch {
    return
  }
  const child = spawn('sh', ['-c', REFRESH_SH], {
    detached: true,
    stdio: 'ignore',
    env: { ...process.env, CACHE: cache, LOCK: lock },
  })
  child.unref()
}

// The cached usage payload, refreshing it in the background when stale. A
// stale read still renders: the countdown comes from resets_at, not from when
// the fetch happened.
function readUsage() {
  const file = usageCachePath()
  const age = ageMs(file)
  if (age === null) {
    spawnRefresh(file)
    return null
  }
  if (age >= USAGE_TTL_MS) spawnRefresh(file)
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'))
  } catch {
    return null
  }
}

function until(ms) {
  const total = Math.floor(ms / 60_000)
  const hours = Math.floor(total / 60)
  const mins = total % 60
  if (hours >= 24) return `${Math.floor(hours / 24)}d${hours % 24}h`
  if (hours >= 1) return `${hours}h${mins}m`
  return `${mins}m`
}

function usageSegment(usage, key, label) {
  const window = usage[key]
  if (!window || typeof window.utilization !== 'number') return null
  const pct = Math.round(window.utilization)
  if (pct < USAGE_SHOW_AT_PCT) return null
  const color = pct >= 85 ? 31 : pct >= 65 ? 33 : 32
  let segment = `${dim(label)} ${paint(color, `${pct}%`)}`
  if (window.resets_at) {
    const left = Date.parse(window.resets_at) - Date.now()
    if (left > 0) segment += ` ${dim(until(left))}`
  }
  return segment
}

const data = readStdin()
const parts = []

const profile = profileLabel()
if (profile) parts.push(dim(profile))

// Model — trim the verbose "(1M context)" suffix the harness sends.
const model = (data.model && data.model.display_name) || (data.model && data.model.id)
if (model) parts.push(paint(36, model.replace(/\s*\(1M context\)$/, ' 1M')))

const tail = data.transcript_path ? readTail(data.transcript_path) : null

if (tail) {
  const u = tail.usage
  // input + both cache buckets is what the last request carried; output rolls
  // into the next one, so counting it tracks what the window is about to hold.
  const used =
    (u.input_tokens || 0) +
    (u.cache_creation_input_tokens || 0) +
    (u.cache_read_input_tokens || 0) +
    (u.output_tokens || 0)

  const id = (data.model && data.model.id) || ''
  // Plain substring match, matching the Rust build's `contains` — a \b here
  // would make the two disagree on ids like "…-1million".
  let limit = /\[1m\]|-1m/i.test(id) ? 1_000_000 : 200_000
  if (used > limit) limit = 1_000_000 // model id didn't advertise it; trust the count

  const pct = Math.round((used / limit) * 100)
  const color = pct >= 85 ? 31 : pct >= 65 ? 33 : 32
  parts.push(`${paint(color, `${compact(used)}/${compact(limit)}`)} ${dim(`${pct}%`)}`)
}

const cost = data.cost && data.cost.total_cost_usd
if (typeof cost === 'number') {
  let segment = `$${cost.toFixed(2)}`
  // Burn rate against wall-clock session time. Suppressed under a minute,
  // where dividing by a near-zero duration produces a meaningless number.
  let elapsed = data.cost && data.cost.total_duration_ms
  if (typeof elapsed !== 'number' && tail && tail.ts) {
    const started = firstTimestamp(data.transcript_path)
    if (started) elapsed = Date.parse(tail.ts) - Date.parse(started)
  }
  if (typeof elapsed === 'number' && elapsed >= 60_000) {
    const perHour = cost / (elapsed / 3_600_000)
    segment += ` ${dim(`$${perHour >= 10 ? perHour.toFixed(0) : perHour.toFixed(2)}/h`)}`
  }
  parts.push(segment)
}

if (tail && tail.ts) {
  const expiresAt = Date.parse(tail.ts) + tail.ttlMs
  const left = expiresAt - Date.now()
  if (left <= 0) {
    parts.push(paint(31, 'cache expired'))
  } else {
    const mins = Math.floor(left / 60_000)
    const label = mins >= 1 ? `${mins}m` : `${Math.floor(left / 1000)}s`
    const color = left > 15 * 60_000 ? 32 : left > 5 * 60_000 ? 33 : 31
    parts.push(`${dim('cache')} ${paint(color, label)} ${dim(`(${clock(expiresAt)})`)}`)
  }
}

const usage = readUsage()
if (usage) {
  for (const segment of [
    usageSegment(usage, 'five_hour', '5h'),
    usageSegment(usage, 'seven_day', '7d'),
  ]) {
    if (segment) parts.push(segment)
  }
}

process.stdout.write(parts.join(dim(' | ')))
