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
// Ceiling for the failure backoff. The endpoint goes down often enough that a
// fixed retry interval turns an outage into a steady drip of doomed forks.
const USAGE_MAX_BACKOFF_MS = 3600_000
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

const configDir = () =>
  process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude')

// refresh.sh, which does the fetch. Installed beside the config dir; the
// override is for running out of a checkout, and for tests.
function refreshScript() {
  const script =
    process.env.CLAUDE_STATUSLINE_REFRESH || path.join(configDir(), 'refresh.sh')
  try {
    return fs.statSync(script).isFile() ? script : null
  } catch {
    return null
  }
}

// Walks up from `start` looking for `.git`, so a branch shows from any
// subdirectory of a repo, not just its root. Handles worktrees and
// submodules, whose `.git` is a file pointing elsewhere via `gitdir: <path>`.
function findGitDir(start) {
  let dir = start
  for (;;) {
    const candidate = path.join(dir, '.git')
    let stat
    try {
      stat = fs.statSync(candidate)
    } catch {
      stat = null
    }
    if (stat && stat.isDirectory()) return candidate
    if (stat && stat.isFile()) {
      let contents
      try {
        contents = fs.readFileSync(candidate, 'utf8').trim()
      } catch {
        return null
      }
      const match = contents.match(/^gitdir:\s*(.+)$/)
      if (!match) return null
      return path.isAbsolute(match[1]) ? match[1] : path.join(dir, match[1])
    }
    const parent = path.dirname(dir)
    if (parent === dir) return null
    dir = parent
  }
}

// Directory holding .git (dir or file), walking up from `start`. For a linked
// worktree this is the worktree's own checkout directory, not the main
// repo's — its basename is what `git worktree list` calls it.
function findWorktreeRoot(start) {
  let dir = start
  for (;;) {
    if (fs.existsSync(path.join(dir, '.git'))) return dir
    const parent = path.dirname(dir)
    if (parent === dir) return null
    dir = parent
  }
}

// The name peers address this session by (SendMessage), from the registry the
// harness keeps at $CLAUDE_CONFIG_DIR/sessions/<pid>.json. Ours is the entry
// whose sessionId matches; a handful of small files, so the scan costs less
// than resolving which pid is the harness's.
function sessionName(sessionId) {
  let files
  try {
    files = fs.readdirSync(path.join(configDir(), 'sessions'))
  } catch {
    return null
  }
  for (const file of files) {
    if (file.endsWith('.json')) {
      let entry
      try {
        entry = JSON.parse(
          fs.readFileSync(path.join(configDir(), 'sessions', file), 'utf8'),
        )
      } catch {
        continue
      }
      if (entry && entry.sessionId === sessionId) {
        return typeof entry.name === 'string' ? entry.name : null
      }
    }
  }
  return null
}

function worktreeName(cwd) {
  const root = findWorktreeRoot(cwd)
  return root ? path.basename(root) : null
}

// Branch name straight from .git/HEAD — no git subprocess. Detached HEAD
// renders as a short hash instead of the ref line.
function gitBranch(cwd) {
  const gitDir = findGitDir(cwd)
  if (!gitDir) return null
  let head
  try {
    head = fs.readFileSync(path.join(gitDir, 'HEAD'), 'utf8').trim()
  } catch {
    return null
  }
  const match = head.match(/^ref: refs\/heads\/(.+)$/)
  if (match) return match[1]
  return head.length >= 7 ? head.slice(0, 7) : null
}

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

// Rust's Path::with_extension, which replaces rather than appends.
const sibling = (cache, ext) =>
  path.join(
    path.dirname(cache),
    path.basename(cache, path.extname(cache)) + ext,
  )

// How long to wait after n consecutive failures: 5m, 10m, 20m, 40m, then
// hourly. Zero failures is the ordinary TTL.
const backoffMs = fails =>
  Math.min(USAGE_TTL_MS * 2 ** Math.min(fails, 8), USAGE_MAX_BACKOFF_MS)

// Whether enough time has passed since the last attempt. The cache is
// rewritten on success and the fail file on failure, so the fresher of the two
// is when the endpoint was last called.
function shouldRefresh(cache, failFile) {
  let fails = 0
  try {
    const parsed = parseInt(fs.readFileSync(failFile, 'utf8').trim(), 10)
    if (Number.isInteger(parsed) && parsed >= 0) fails = parsed
  } catch {
    /* no failures recorded */
  }
  const ages = [ageMs(cache), ageMs(failFile)].filter(age => age !== null)
  if (!ages.length) return true
  return Math.min(...ages) >= backoffMs(fails)
}

// Fire-and-forget refresh. The lock keeps concurrent sessions from stampeding
// the endpoint; it is taken over if a previous refresh died holding it.
function spawnRefresh(cache) {
  if (process.env.CLAUDE_STATUSLINE_NO_REFRESH) return
  // Resolved before the lock is taken: a missing script must not leave one
  // behind, and the stat costs nothing next to the fork it guards.
  const script = refreshScript()
  if (!script) return
  const lock = sibling(cache, '.lock')
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
  try {
    const child = spawn('sh', [script], {
      detached: true,
      stdio: 'ignore',
      env: {
        ...process.env,
        CACHE: cache,
        LOCK: lock,
        FAIL: sibling(cache, '.fail'),
      },
    })
    child.unref()
  } catch {
    // Nothing will release the lock if the fork itself failed.
    try {
      fs.unlinkSync(lock)
    } catch {
      /* already gone */
    }
  }
}

// The cached usage payload, refreshing it in the background when stale. A
// stale read still renders: the countdown comes from resets_at, not from when
// the fetch happened.
function readUsage() {
  const file = usageCachePath()
  if (shouldRefresh(file, sibling(file, '.fail'))) spawnRefresh(file)
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
  // Date.parse yields NaN where Rust's parse yields None; both must land on
  // null, or an unparseable timestamp renders "NaNhNaNm" in the Node build
  // alone and the two stop agreeing.
  const at = window.resets_at ? Date.parse(window.resets_at) : NaN
  const left = Number.isNaN(at) ? null : at - Date.now()
  // Past its reset the window has rolled over, so the cached percentage
  // describes a window that no longer exists. That only happens when the
  // refresh has been failing — an expired token, no curl, no network — and a
  // frozen "80%" over a window that is actually empty is worse than silence.
  if (left !== null && left <= 0) return null
  if (left !== null) segment += ` ${dim(until(left))}`
  return segment
}

const data = readStdin()
const parts = []

const profile = profileLabel()
if (profile) parts.push(dim(profile))

const worktree = data.cwd ? worktreeName(data.cwd) : null
// The peer name already opens with the project basename ("dotfiles-4f"), so it
// stands in for the worktree field rather than repeating it.
const peer = data.session_id ? sessionName(data.session_id) : null
const coversWorktree =
  peer !== null &&
  worktree !== null &&
  peer.startsWith(worktree) &&
  (peer.length === worktree.length || peer[worktree.length] === '-')
if (worktree && !coversWorktree) parts.push(paint(34, worktree))
if (peer) parts.push(paint(34, peer))

const branch = data.cwd ? gitBranch(data.cwd) : null
if (branch) parts.push(paint(35, branch))

// Model — trim the verbose "(1M context)" suffix the harness sends.
const model = (data.model && data.model.display_name) || (data.model && data.model.id)
if (model) parts.push(paint(36, model.replace(/\s*\(1M context\)$/, ' 1M')))

const effortLevel = data.effort && data.effort.level
if (typeof effortLevel === 'string') {
  const effortColor = { low: 32, medium: 32, high: 33 }[effortLevel] || 31 // xhigh, max, and anything future
  parts.push(paint(effortColor, effortLevel))
}

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
  const oneM = /\[1m\]|-1m/i.test(id) || (model || '').endsWith('(1M context)')
  let limit = oneM ? 1_000_000 : 200_000
  if (used > limit) limit = 1_000_000 // neither id nor label advertised it; trust the count

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
