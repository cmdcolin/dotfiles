//! Minimal Claude Code statusline: model | context | cost | cache expiry.
//!
//! Transcripts reach tens of megabytes, so the last usage record is found by
//! seeking from the end of the file rather than parsing it. Everything here is
//! sized to run in a couple of milliseconds, because the harness re-renders the
//! statusline constantly.

use chrono::{DateTime, Local, TimeZone, Timelike, Utc};
use serde_json::Value;
use std::fs::File;
use std::io::{Read, Seek, SeekFrom, Write};

const HOUR_MS: i64 = 3_600_000;
const FIVE_MIN_MS: i64 = 300_000;

const GREEN: &str = "32";
const YELLOW: &str = "33";
const RED: &str = "31";
const CYAN: &str = "36";

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

fn main() {
    let mut input = String::new();
    if std::io::stdin().read_to_string(&mut input).is_err() {
        return;
    }
    let data: Value = serde_json::from_str(&input).unwrap_or(Value::Null);

    let mut parts: Vec<String> = Vec::new();

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
        let mut limit = if id.contains("[1m]") || id.contains("-1m") {
            1_000_000
        } else {
            200_000
        };
        if tail.used > limit {
            limit = 1_000_000; // model id didn't advertise it; trust the count
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

    let sep = dim(" | ");
    let _ = std::io::stdout().write_all(parts.join(&sep).as_bytes());
}
