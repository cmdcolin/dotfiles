//! Minimal Claude Code statusline.
//!
//! Everything but the profile label, the peer name and the git branch comes
//! straight out of the JSON the harness writes to stdin — token counts, cache
//! expiry and rate-limit windows included. The three exceptions are cheap file
//! reads, so a render is a JSON parse and a handful of `stat` calls.

use chrono::{Local, TimeZone, Timelike, Utc};
use serde_json::Value;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

/// Below this a rate-limit window is not worth the width; it is the tail that
/// matters.
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

/// The shared scale for anything measured as a percentage of a ceiling.
fn heat(pct: i64) -> &'static str {
    if pct >= 85 {
        RED
    } else if pct >= 65 {
        YELLOW
    } else {
        GREEN
    }
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

fn int(v: &Value, key: &str) -> i64 {
    v.get(key).and_then(Value::as_i64).unwrap_or(0)
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

/// One plan window: percentage plus a countdown to its reset.
fn usage_segment(limits: &Value, key: &str, label: &str) -> Option<String> {
    let window = limits.get(key)?;
    let pct = window.get("used_percentage").and_then(Value::as_i64)?;
    if pct < USAGE_SHOW_AT_PCT {
        return None;
    }
    let mut segment = format!("{} {}", dim(label), paint(heat(pct), &format!("{pct}%")));
    if let Some(resets_at) = window.get("resets_at").and_then(Value::as_i64) {
        let left = resets_at * 1000 - Utc::now().timestamp_millis();
        if left > 0 {
            segment.push(' ');
            segment.push_str(&dim(&until(left)));
        }
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

    // The harness's own used_percentage counts input alone; output rolls into
    // the next request, so counting it tracks what the window is about to hold.
    if let Some(window) = data.get("context_window") {
        let limit = window
            .get("context_window_size")
            .and_then(Value::as_i64)
            .unwrap_or(0);
        if limit > 0 {
            let used = int(window, "total_input_tokens") + int(window, "total_output_tokens");
            let pct = ((used as f64 / limit as f64) * 100.0).round() as i64;
            parts.push(format!(
                "{} {}",
                paint(heat(pct), &format!("{}/{}", compact(used), compact(limit))),
                dim(&format!("{pct}%"))
            ));
        }
    }

    if let Some(cost) = data.pointer("/cost/total_cost_usd").and_then(Value::as_f64) {
        let mut segment = format!("${cost:.2}");
        // Burn rate against wall-clock session time. Suppressed under a minute,
        // where dividing by a near-zero duration produces a meaningless number.
        let elapsed = data
            .pointer("/cost/total_duration_ms")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
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
        parts.push(segment);
    }

    // Absent until the session has written a cache block, so a cold or
    // just-resumed session renders no cache field rather than a placeholder.
    if let Some(expires_at) = data
        .pointer("/prompt_cache/expires_at")
        .and_then(Value::as_i64)
    {
        let expires_ms = expires_at * 1000;
        let left = expires_ms - Utc::now().timestamp_millis();
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
                dim(&format!("({})", clock(expires_ms)))
            ));
        }
    }

    if let Some(limits) = data.get("rate_limits") {
        parts.extend(usage_segment(limits, "five_hour", "5h"));
        parts.extend(usage_segment(limits, "seven_day", "7d"));
    }

    let sep = dim(" | ");
    let _ = std::io::stdout().write_all(parts.join(&sep).as_bytes());
}
