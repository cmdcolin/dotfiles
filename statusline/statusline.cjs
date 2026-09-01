#!/usr/bin/env node
// Minimal Claude Code statusline.
//
// Everything but the profile label, the peer name and the git branch comes
// straight out of the JSON the harness writes to stdin — token counts, cache
// expiry and rate-limit windows included. Dependency-free; kept byte-identical
// to the Rust build, which test.sh enforces.

const fs = require('fs')
const os = require('os')
const path = require('path')

const RESET = '\x1b[0m'
const paint = (code, text) => `\x1b[${code}m${text}${RESET}`
const dim = text => paint(2, text)

// Below this a rate-limit window is not worth the width; it is the tail that
// matters.
const USAGE_SHOW_AT_PCT = 50

// The shared scale for anything measured as a percentage of a ceiling.
const heat = pct => (pct >= 85 ? 31 : pct >= 65 ? 33 : 32)

function readStdin() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'))
  } catch {
    return {}
  }
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

function until(ms) {
  const total = Math.floor(ms / 60_000)
  const hours = Math.floor(total / 60)
  const mins = total % 60
  if (hours >= 24) return `${Math.floor(hours / 24)}d${hours % 24}h`
  if (hours >= 1) return `${hours}h${mins}m`
  return `${mins}m`
}

const configDir = () =>
  process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude')

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

// The name peers address this session by (SendMessage), from the registry the
// harness keeps at $CLAUDE_CONFIG_DIR/sessions/<pid>.json. Ours is the entry
// whose sessionId matches; a handful of small files, so the scan costs less
// than resolving which pid is the harness's.
function sessionName(sessionId) {
  const dir = path.join(configDir(), 'sessions')
  let files
  try {
    files = fs.readdirSync(dir)
  } catch {
    return null
  }
  for (const file of files) {
    if (file.endsWith('.json')) {
      let entry
      try {
        entry = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'))
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

// One plan window: percentage plus a countdown to its reset.
function usageSegment(limits, key, label) {
  const window = limits[key]
  if (!window || typeof window.used_percentage !== 'number') return null
  const pct = window.used_percentage
  if (pct < USAGE_SHOW_AT_PCT) return null
  let segment = `${dim(label)} ${paint(heat(pct), `${pct}%`)}`
  if (typeof window.resets_at === 'number') {
    const left = window.resets_at * 1000 - Date.now()
    if (left > 0) segment += ` ${dim(until(left))}`
  }
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

// The harness's own used_percentage counts input alone; output rolls into the
// next request, so counting it tracks what the window is about to hold.
const window = data.context_window
if (window) {
  const limit = window.context_window_size
  if (typeof limit === 'number' && limit > 0) {
    const used = (window.total_input_tokens || 0) + (window.total_output_tokens || 0)
    const pct = Math.round((used / limit) * 100)
    parts.push(`${paint(heat(pct), `${compact(used)}/${compact(limit)}`)} ${dim(`${pct}%`)}`)
  }
}

const cost = data.cost && data.cost.total_cost_usd
if (typeof cost === 'number') {
  let segment = `$${cost.toFixed(2)}`
  // Burn rate against wall-clock session time. Suppressed under a minute,
  // where dividing by a near-zero duration produces a meaningless number.
  const elapsed = (data.cost && data.cost.total_duration_ms) || 0
  if (elapsed >= 60_000) {
    const perHour = cost / (elapsed / 3_600_000)
    segment += ` ${dim(`$${perHour >= 10 ? perHour.toFixed(0) : perHour.toFixed(2)}/h`)}`
  }
  parts.push(segment)
}

// Absent until the session has written a cache block, so a cold or
// just-resumed session renders no cache field rather than a placeholder.
const expiresAt = data.prompt_cache && data.prompt_cache.expires_at
if (typeof expiresAt === 'number') {
  const expiresMs = expiresAt * 1000
  const left = expiresMs - Date.now()
  if (left <= 0) {
    parts.push(paint(31, 'cache expired'))
  } else {
    const mins = Math.floor(left / 60_000)
    const label = mins >= 1 ? `${mins}m` : `${Math.floor(left / 1000)}s`
    const color = left > 15 * 60_000 ? 32 : left > 5 * 60_000 ? 33 : 31
    parts.push(`${dim('cache')} ${paint(color, label)} ${dim(`(${clock(expiresMs)})`)}`)
  }
}

if (data.rate_limits) {
  for (const segment of [
    usageSegment(data.rate_limits, 'five_hour', '5h'),
    usageSegment(data.rate_limits, 'seven_day', '7d'),
  ]) {
    if (segment) parts.push(segment)
  }
}

process.stdout.write(parts.join(dim(' | ')))
