#!/usr/bin/env node
// Minimal Claude Code statusline: model | context | cost | cache expiry.
//
// Deliberately dependency-free and tail-reading: transcripts reach tens of MB,
// so we seek the last usage record from the end of the file instead of parsing
// it. Target is a few ms of CPU per render.

const fs = require('fs')

const RESET = '\x1b[0m'
const paint = (code, text) => `\x1b[${code}m${text}${RESET}`
const dim = text => paint(2, text)

const HOUR_MS = 3600_000
const FIVE_MIN_MS = 300_000

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

const data = readStdin()
const parts = []

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

process.stdout.write(parts.join(dim(' | ')))
