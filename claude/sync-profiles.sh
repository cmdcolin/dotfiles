#!/usr/bin/env bash
# Push settings.base.json into every ~/.claude* profile and install the
# statusline into each.
#
# The profiles exist to run several Claude sessions side by side, so anything
# that is a preference rather than a per-profile fact should be identical in
# all of them. They drift instead: a setting gets changed in whichever profile
# is in front of you, the others keep the old value, and the difference is
# invisible until one behaves oddly.
#
# Merge rule: the base file is authoritative for the keys it defines, and keys
# it does not mention are left alone. That keeps genuinely per-profile settings
# -- effortLevel, credentials, survey state -- without having to list them.
# statusLine is the exception, rewritten per profile because it names a path
# inside that profile.
#
# Re-runnable. Pass --dry-run to see the diff without writing.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$DIR/settings.base.json"
DRY=""
[ "${1:-}" = "--dry-run" ] && DRY=1

for cfg in "$HOME"/.claude "$HOME"/.claude[0-9]; do
  [ -d "$cfg" ] || continue
  settings="$cfg/settings.json"
  [ -f "$settings" ] || { echo "skip $cfg (no settings.json)"; continue; }

  echo "=== $cfg ==="
  BASE="$BASE" CFG="$cfg" SETTINGS="$settings" DRY="$DRY" python3 - <<'PY'
import json, os, shutil, sys

base = json.load(open(os.environ["BASE"]))
path = os.environ["SETTINGS"]
cur = json.load(open(path))
new = dict(cur)

# The base wins for what it defines; enabledPlugins merges key by key so a
# plugin enabled in one profile only is still turned off, not dropped.
for k, v in base.items():
    if k == "enabledPlugins":
        merged = dict(cur.get(k, {}))
        merged.update(v)
        new[k] = merged
    else:
        new[k] = v

# Points into this profile, so it cannot come from a shared file.
new["statusLine"] = {
    "type": "command",
    "command": os.path.join(os.environ["CFG"], "bin", "statusline"),
}

changes = [k for k in sorted(set(cur) | set(new)) if cur.get(k) != new.get(k)]
if not changes:
    print("  already in sync")
    sys.exit(0)

for k in changes:
    print(f"  {k}: {json.dumps(cur.get(k))} -> {json.dumps(new.get(k))}")

if os.environ["DRY"]:
    print("  (dry run, not written)")
    sys.exit(0)

shutil.copy2(path, path + ".bak")
with open(path, "w") as f:
    json.dump(new, f, indent=2)
    f.write("\n")
print(f"  written (backup at {os.path.basename(path)}.bak)")
PY

  if [ -z "$DRY" ]; then
    CLAUDE_CONFIG_DIR="$cfg" "$DIR/../statusline/install.sh" >/dev/null
    echo "  statusline installed"
  fi
done

echo
echo "Note: a running Claude session may rewrite its own settings.json on exit."
echo "Re-run this afterwards if a profile drifts back."
