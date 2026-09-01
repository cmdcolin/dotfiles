//! Minimal Claude Code statusline: model | context | cost | cache expiry.
//!
//! Transcripts reach tens of megabytes, so the last usage record is found by
//! seeking from the end of the file rather than parsing it. Everything here is
//! sized to run in a couple of milliseconds, because the harness re-renders the
//! statusline constantly.

use chrono::{DateTime, Local, TimeZone, Timelike, Utc};
use serde_json::Value;
use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::SystemTime;

const HOUR_MS: i64 = 3_600_000;
const FIVE_MIN_MS: i64 = 300_000;

/// Rate-limit windows move slowly, and the reset countdown is computed locally
/// from the cached `resets_at`, so only the percentage ages between refreshes.
const USAGE_TTL_SECS: u64 = 300;
/// Ceiling for the failure backoff. The endpoint goes down often enough that a
/// fixed retry interval turns an outage into a steady drip of doomed forks.
const USAGE_MAX_BACKOFF_SECS: u64 = 3600;
const USAGE_LOCK_STALE_SECS: u64 = 120;
/// Below this the window is not worth the width; it is the tail that matters.
const USAGE_SHOW_AT_PCT: i64 = 50;

const GREEN: &str = "32";
const YELLOW: &str = "33";
const RED: &str = "31";
const CYAN: &str = "36";
const MAGENTA: &str = "35";
const BLUE: &str = "34";

fn paint(code: &str, text: &str) -> String {
    format!("\x1b[{code}m{text}\x1b[0m")
}

fn dim(text: &str) -> String {
    paint("2", text)
}

fn trim_zeros(s: String) -> String {
    if s.contains('.') {
        s.trim_end_matches('0').trim_end_matches('.').to_string()
    } else {
        s
    }
}

fn compact(n: i64) -> String {
    if n >= 1_000_000 {
        format!("{}M", trim_zeros(format!("{:.2}", n as f64 / 1e6)))
    } else if n >= 1000 {
        let places = if n >= 100_000 { 0 } else { 1 };
        format!("{}k", trim_zeros(format!("{:.*}", places, n as f64 / 1e3)))
    } else {
        n.to_string()
    }
}

struct Tail {
    used: i64,
    ts: String,
    ttl_ms: i64,
}

fn int(v: &Value, key: &str) -> i64 {
    v.get(key).and_then(Value::as_i64).unwrap_or(0)
}

/// Newest main-thread usage record in the tail of the transcript. Sidechain
/// (subagent) entries are skipped: their token counts belong to the subagent's
/// window, not ours, and would make the meter jump around.
fn read_tail(path: &str) -> Option<Tail> {
    let mut file = File::open(path).ok()?;
    let size = file.metadata().ok()?.len();

    for window in [64 * 1024u64, 1024 * 1024, 8 * 1024 * 1024] {
        let start = size.saturating_sub(window);
        file.seek(SeekFrom::Start(start)).ok()?;
        let mut buf = Vec::with_capacity((size - start) as usize);
        Read::by_ref(&mut file)
            .take(size - start)
            .read_to_end(&mut buf)
            .ok()?;

        let text = String::from_utf8_lossy(&buf);
        let mut lines: Vec<&str> = text.split('\n').collect();
        if start > 0 && !lines.is_empty() {
            lines.remove(0); // partial line, and any split multibyte char
        }

        let mut latest: Option<(i64, String)> = None;
        let mut ttl_ms: Option<i64> = None;

        for line in lines.iter().rev() {
            if line.len() < 2 || !line.contains("\"usage\"") {
                continue;
            }
            let Ok(entry) = serde_json::from_str::<Value>(line) else {
                continue;
            };
            if entry
                .get("isSidechain")
                .and_then(Value::as_bool)
                .unwrap_or(false)
            {
                continue;
            }
            let Some(usage) = entry.pointer("/message/usage") else {
                continue;
            };

            if latest.is_none() {
                // input + both cache buckets is what the last request carried;
                // output rolls into the next one, so counting it tracks what
                // the window is about to hold.
                let used = int(usage, "input_tokens")
                    + int(usage, "cache_creation_input_tokens")
                    + int(usage, "cache_read_input_tokens")
                    + int(usage, "output_tokens");
                let ts = entry
                    .get("timestamp")
                    .and_then(Value::as_str)
                    .unwrap_or_default()
                    .to_string();
                latest = Some((used, ts));
            }

            // Which TTL this session negotiated. The newest turn may have
            // created no cache blocks at all, so keep looking back.
            if ttl_ms.is_none() {
                if let Some(created) = usage.get("cache_creation") {
                    if int(created, "ephemeral_1h_input_tokens") > 0 {
                        ttl_ms = Some(HOUR_MS);
                    } else if int(created, "ephemeral_5m_input_tokens") > 0 {
                        ttl_ms = Some(FIVE_MIN_MS);
                    }
                }
            }

            if latest.is_some() && ttl_ms.is_some() {
                break;
            }
        }

        if let Some((used, ts)) = latest {
            return Some(Tail {
                used,
                ts,
                ttl_ms: ttl_ms.unwrap_or(HOUR_MS),
            });
        }
        if start == 0 {
            break;
        }
    }
    None
}

/// Session start, for the burn rate. The harness may or may not send
/// cost.total_duration_ms, so fall back to the transcript's own span.
fn first_timestamp(path: &str) -> Option<String> {
    let mut file = File::open(path).ok()?;
    let mut buf = vec![0u8; 64 * 1024];
    let read = Read::by_ref(&mut file).read(&mut buf).ok()?;
    let text = String::from_utf8_lossy(&buf[..read]);
    for line in text.split('\n') {
        if line.len() < 2 || !line.contains("\"timestamp\"") {
            continue;
        }
        // A truncated final line simply fails to parse and is skipped.
        if let Ok(entry) = serde_json::from_str::<Value>(line) {
            if let Some(ts) = entry.get("timestamp").and_then(Value::as_str) {
                return Some(ts.to_string());
            }
        }
    }
    None
}

fn clock(ms: i64) -> String {
    let Some(local) = Local.timestamp_millis_opt(ms).single() else {
        return String::new();
    };
    let hour = match local.hour() % 12 {
        0 => 12,
        h => h,
    };
    format!("{}:{:02}", hour, local.minute())
}

/// `refresh.sh`, which does the fetch. Installed beside the config dir; the
/// override is for running out of a checkout, and for tests.
fn refresh_script() -> Option<PathBuf> {
    let path = std::env::var_os("CLAUDE_STATUSLINE_REFRESH")
        .map(PathBuf::from)
        .unwrap_or_else(|| config_dir().join("refresh.sh"));
    path.is_file().then_some(path)
}

fn config_dir() -> PathBuf {
    if let Some(dir) = std::env::var_os("CLAUDE_CONFIG_DIR") {
        return PathBuf::from(dir);
    }
    PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".claude")
}

/// Walks up from `start` looking for `.git`, so a branch shows from any
/// subdirectory of a repo, not just its root. Handles worktrees and
/// submodules, whose `.git` is a file pointing elsewhere via `gitdir: <path>`.
fn find_git_dir(start: &Path) -> Option<PathBuf> {
    let mut dir = start.to_path_buf();
    loop {
        let candidate = dir.join(".git");
        if candidate.is_dir() {
            return Some(candidate);
        }
        if candidate.is_file() {
            let contents = std::fs::read_to_string(&candidate).ok()?;
            let gitdir = contents.trim().strip_prefix("gitdir:")?.trim();
            let gitdir = PathBuf::from(gitdir);
            return Some(if gitdir.is_absolute() {
                gitdir
            } else {
                dir.join(gitdir)
            });
        }
        if !dir.pop() {
            return None;
        }
    }
}

/// Directory holding `.git` (dir or file), walking up from `start`. For a
/// linked worktree this is the worktree's own checkout directory, not the
/// main repo's — its basename is what `git worktree list` calls it.
fn find_worktree_root(start: &Path) -> Option<PathBuf> {
    let mut dir = start.to_path_buf();
    loop {
        if dir.join(".git").exists() {
            return Some(dir);
        }
        if !dir.pop() {
            return None;
        }
    }
}

/// The name peers address this session by (`SendMessage`), from the registry
/// the harness keeps at `$CLAUDE_CONFIG_DIR/sessions/<pid>.json`. Ours is the
/// entry whose `sessionId` matches; a handful of small files, so the scan
/// costs less than resolving which pid is the harness's.
fn session_name(session_id: &str) -> Option<String> {
    std::fs::read_dir(config_dir().join("sessions"))
        .ok()?
        .flatten()
        .filter(|entry| entry.path().extension().is_some_and(|ext| ext == "json"))
        .filter_map(|entry| std::fs::read_to_string(entry.path()).ok())
        .filter_map(|text| serde_json::from_str::<Value>(&text).ok())
        .find(|entry| entry.get("sessionId").and_then(Value::as_str) == Some(session_id))
        .and_then(|entry| entry.get("name").and_then(Value::as_str).map(String::from))
}

fn worktree_name(cwd: &str) -> Option<String> {
    find_worktree_root(Path::new(cwd))?
        .file_name()?
        .to_str()
        .map(|s| s.to_string())
}

/// Branch name straight from `.git/HEAD` — no `git` subprocess. Detached HEAD
/// renders as a short hash instead of the ref line.
fn git_branch(cwd: &str) -> Option<String> {
    let head = std::fs::read_to_string(find_git_dir(Path::new(cwd))?.join("HEAD")).ok()?;
    let head = head.trim();
    match head.strip_prefix("ref: refs/heads/") {
        Some(name) => Some(name.to_string()),
        None => (head.len() >= 7).then(|| head[..7].to_string()),
    }
}

/// Which config dir this session is running under: `.claude2` -> `claude2`.
fn profile_label() -> Option<String> {
    let dir = config_dir();
    let name = dir.file_name()?.to_str()?;
    let name = name.strip_prefix('.').unwrap_or(name);
    (!name.is_empty()).then(|| name.to_string())
}

fn usage_cache_path() -> PathBuf {
    if let Some(path) = std::env::var_os("CLAUDE_STATUSLINE_USAGE_CACHE") {
        return PathBuf::from(path);
    }
    // Per profile: separate config dirs can be separate accounts.
    let profile = profile_label().unwrap_or_else(|| "default".to_string());
    std::env::temp_dir().join(format!("claude-statusline-usage-{profile}.json"))
}

fn age_secs(path: &Path) -> Option<u64> {
    let modified = std::fs::metadata(path).ok()?.modified().ok()?;
    SystemTime::now()
        .duration_since(modified)
        .ok()
        .map(|age| age.as_secs())
}

/// How long to wait after `fails` consecutive failures: 5m, 10m, 20m, 40m,
/// then hourly. Zero failures is the ordinary TTL.
fn backoff_secs(fails: u32) -> u64 {
    USAGE_TTL_SECS
        .saturating_mul(1u64 << fails.min(8))
        .min(USAGE_MAX_BACKOFF_SECS)
}

/// Whether enough time has passed since the last attempt. The cache is
/// rewritten on success and the fail file on failure, so the fresher of the two
/// is when the endpoint was last called.
fn should_refresh(cache: &Path, fails: &Path) -> bool {
    let wait = backoff_secs(
        std::fs::read_to_string(fails)
            .ok()
            .and_then(|n| n.trim().parse().ok())
            .unwrap_or(0),
    );
    match [age_secs(cache), age_secs(fails)]
        .into_iter()
        .flatten()
        .min()
    {
        None => true,
        Some(since_attempt) => since_attempt >= wait,
    }
}

/// Fire-and-forget refresh. The lock keeps concurrent sessions from stampeding
/// the endpoint; it is taken over if a previous refresh died holding it.
fn spawn_refresh(cache: &Path) {
    if std::env::var_os("CLAUDE_STATUSLINE_NO_REFRESH").is_some() {
        return;
    }
    // Resolved before the lock is taken: a missing script must not leave one
    // behind, and the stat costs nothing next to the fork it guards.
    let Some(script) = refresh_script() else {
        return;
    };
    let lock = cache.with_extension("lock");
    if let Some(age) = age_secs(&lock) {
        if age < USAGE_LOCK_STALE_SECS {
            return;
        }
        let _ = std::fs::remove_file(&lock);
    }
    if OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&lock)
        .is_err()
    {
        return;
    }
    let spawned = Command::new("sh")
        .arg(&script)
        .env("CACHE", cache)
        .env("LOCK", &lock)
        .env("FAIL", cache.with_extension("fail"))
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
    // Nothing will release the lock if the fork itself failed.
    if spawned.is_err() {
        let _ = std::fs::remove_file(&lock);
    }
}

/// The cached usage payload, refreshing it in the background when stale. A
/// stale read still renders: the countdown comes from `resets_at`, not from
/// when the fetch happened.
fn read_usage() -> Option<Value> {
    let path = usage_cache_path();
    if should_refresh(&path, &path.with_extension("fail")) {
        spawn_refresh(&path);
    }
    serde_json::from_str(&std::fs::read_to_string(&path).ok()?).ok()
}

fn until(ms: i64) -> String {
    let mins = ms / 60_000;
    let (hours, mins) = (mins / 60, mins % 60);
    if hours >= 24 {
        format!("{}d{}h", hours / 24, hours % 24)
    } else if hours >= 1 {
        format!("{hours}h{mins}m")
    } else {
        format!("{mins}m")
    }
}

fn usage_segment(usage: &Value, key: &str, label: &str) -> Option<String> {
    let window = usage.get(key)?;
    let pct = window.get("utilization").and_then(Value::as_f64)?.round() as i64;
    if pct < USAGE_SHOW_AT_PCT {
        return None;
    }
    let color = if pct >= 85 {
        RED
    } else if pct >= 65 {
        YELLOW
    } else {
        GREEN
    };
    let mut segment = format!("{} {}", dim(label), paint(color, &format!("{pct}%")));
    let left = window
        .get("resets_at")
        .and_then(Value::as_str)
        .and_then(|at| DateTime::parse_from_rfc3339(at).ok())
        .map(|at| at.timestamp_millis() - Utc::now().timestamp_millis());
    // Past its reset the window has rolled over, so the cached percentage
    // describes a window that no longer exists. That only happens when the
    // refresh has been failing — an expired token, no curl, no network — and a
    // frozen "80%" over a window that is actually empty is worse than silence.
    if left.is_some_and(|left| left <= 0) {
        return None;
    }
    if let Some(left) = left {
        segment.push(' ');
        segment.push_str(&dim(&until(left)));
    }
    Some(segment)
}

fn main() {
    let mut input = String::new();
    if std::io::stdin().read_to_string(&mut input).is_err() {
        return;
    }
    let data: Value = serde_json::from_str(&input).unwrap_or(Value::Null);

    let mut parts: Vec<String> = Vec::new();

    if let Some(profile) = profile_label() {
        parts.push(dim(&profile));
    }

    let cwd = data.get("cwd").and_then(Value::as_str);

    let worktree = cwd.and_then(worktree_name);
    // The peer name already opens with the project basename ("dotfiles-4f"),
    // so it stands in for the worktree field rather than repeating it.
    let peer = data
        .get("session_id")
        .and_then(Value::as_str)
        .and_then(session_name);
    let covers_worktree = |name: &String, worktree: &String| {
        name.strip_prefix(worktree.as_str())
            .is_some_and(|rest| rest.is_empty() || rest.starts_with('-'))
    };
    if let Some(worktree) = &worktree {
        if !peer.as_ref().is_some_and(|name| covers_worktree(name, worktree)) {
            parts.push(paint(BLUE, worktree));
        }
    }
    if let Some(name) = &peer {
        parts.push(paint(BLUE, name));
    }

    if let Some(branch) = cwd.and_then(git_branch) {
        parts.push(paint(MAGENTA, &branch));
    }

    // Model — trim the verbose "(1M context)" suffix the harness sends.
    let model = data
        .pointer("/model/display_name")
        .and_then(Value::as_str)
        .or_else(|| data.pointer("/model/id").and_then(Value::as_str));
    if let Some(model) = model {
        let label = match model.strip_suffix(" (1M context)") {
            Some(base) => format!("{base} 1M"),
            None => model.to_string(),
        };
        parts.push(paint(CYAN, &label));
    }

    if let Some(level) = data.pointer("/effort/level").and_then(Value::as_str) {
        let color = match level {
            "low" | "medium" => GREEN,
            "high" => YELLOW,
            _ => RED, // xhigh, max, and anything future
        };
        parts.push(paint(color, level));
    }

    let tail = data
        .get("transcript_path")
        .and_then(Value::as_str)
        .and_then(read_tail);

    if let Some(tail) = &tail {
        let id = data
            .pointer("/model/id")
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_lowercase();
        let one_m = id.contains("[1m]")
            || id.contains("-1m")
            || matches!(model, Some(m) if m.ends_with("(1M context)"));
        let mut limit = if one_m { 1_000_000 } else { 200_000 };
        if tail.used > limit {
            limit = 1_000_000; // neither id nor label advertised it; trust the count
        }

        let pct = ((tail.used as f64 / limit as f64) * 100.0).round() as i64;
        let color = if pct >= 85 {
            RED
        } else if pct >= 65 {
            YELLOW
        } else {
            GREEN
        };
        parts.push(format!(
            "{} {}",
            paint(color, &format!("{}/{}", compact(tail.used), compact(limit))),
            dim(&format!("{pct}%"))
        ));
    }

    if let Some(cost) = data.pointer("/cost/total_cost_usd").and_then(Value::as_f64) {
        let mut segment = format!("${cost:.2}");
        // Burn rate against wall-clock session time. Suppressed under a minute,
        // where dividing by a near-zero duration produces a meaningless number.
        let elapsed = data
            .pointer("/cost/total_duration_ms")
            .and_then(Value::as_f64)
            .or_else(|| {
                let tail = tail.as_ref()?;
                let path = data.get("transcript_path").and_then(Value::as_str)?;
                let started = DateTime::parse_from_rfc3339(&first_timestamp(path)?).ok()?;
                let last = DateTime::parse_from_rfc3339(&tail.ts).ok()?;
                Some((last.timestamp_millis() - started.timestamp_millis()) as f64)
            });
        if let Some(elapsed) = elapsed {
            if elapsed >= 60_000.0 {
                let per_hour = cost / (elapsed / 3_600_000.0);
                let rate = if per_hour >= 10.0 {
                    format!("${per_hour:.0}/h")
                } else {
                    format!("${per_hour:.2}/h")
                };
                segment.push(' ');
                segment.push_str(&dim(&rate));
            }
        }
        parts.push(segment);
    }

    if let Some(tail) = &tail {
        if let Ok(started) = DateTime::parse_from_rfc3339(&tail.ts) {
            let expires_at = started.timestamp_millis() + tail.ttl_ms;
            let left = expires_at - Utc::now().timestamp_millis();
            if left <= 0 {
                parts.push(paint(RED, "cache expired"));
            } else {
                let mins = left / 60_000;
                let label = if mins >= 1 {
                    format!("{mins}m")
                } else {
                    format!("{}s", left / 1000)
                };
                let color = if left > 15 * 60_000 {
                    GREEN
                } else if left > 5 * 60_000 {
                    YELLOW
                } else {
                    RED
                };
                parts.push(format!(
                    "{} {} {}",
                    dim("cache"),
                    paint(color, &label),
                    dim(&format!("({})", clock(expires_at)))
                ));
            }
        }
    }

    if let Some(usage) = read_usage() {
        parts.extend(usage_segment(&usage, "five_hour", "5h"));
        parts.extend(usage_segment(&usage, "seven_day", "7d"));
    }

    let sep = dim(" | ");
    let _ = std::io::stdout().write_all(parts.join(&sep).as_bytes());
}
