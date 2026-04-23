#!/usr/bin/env bash
# Stop hook: refuses to end the session if HANDOFF.md is stale relative to the
# most recent commit, or if uncommitted non-paperwork changes exist.
# This is the anti-drift mechanism. If it never blocks, it is broken.
# 5-second timeout. Always exits cleanly; uses JSON to decide continue/stop.

set -u
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || { echo '{"continue": true}'; exit 0; }

LOG=".claude/hooks/log.txt"
mkdir -p .claude/hooks
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) stop-hook fired" >> "$LOG" 2>/dev/null || true

# Read stdin (JSON from Claude Code). If stop_hook_active is true we are
# already in a continuation loop — allow stop to avoid infinite re-entry.
# Use Python for robust JSON parsing; grep on JSON is fragile across whitespace
# and nesting.
INPUT=$(cat 2>/dev/null || echo '{}')
is_reentry() {
  printf '%s' "$INPUT" | python -c 'import json,sys
try:
    sys.exit(0 if json.load(sys.stdin).get("stop_hook_active") else 1)
except Exception:
    sys.exit(1)' 2>/dev/null
}
if is_reentry; then
  echo '{"continue": true}'
  exit 0
fi

# Not a git repo yet → allow stop.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"continue": true}'
  exit 0
fi

# HANDOFF.md must exist.
if [ ! -f HANDOFF.md ]; then
  echo '{"continue": false, "stopReason": "HANDOFF.md is missing. Run the /handoff command to create it before ending the session."}'
  exit 0
fi

handoff_mtime=$(stat -c %Y HANDOFF.md 2>/dev/null || stat -f %m HANDOFF.md 2>/dev/null || echo 0)
head_commit_time=$(git log -1 --format=%ct 2>/dev/null || echo 0)

# Uncommitted changes outside paperwork. `cut -c4-` is safe for paths with
# spaces; `awk '{print $NF}'` would only grab the last whitespace-separated token.
uncommitted=$(git status --porcelain 2>/dev/null \
  | cut -c4- \
  | grep -v '^HANDOFF\.md$' \
  | grep -v '^PROGRESS\.md$' \
  | grep -v '^\.claude/hooks/log\.txt$' \
  | wc -l | tr -d ' ')

# Block: uncommitted real work exists and handoff is older than the last commit.
if [ "${uncommitted:-0}" -gt 0 ] && [ "$handoff_mtime" -lt "$head_commit_time" ]; then
  echo '{"continue": false, "stopReason": "Uncommitted changes exist and HANDOFF.md is older than the latest commit. Run /handoff before ending the session so the next session knows where to resume."}'
  exit 0
fi

# Block: handoff is older than the most recent commit → commits happened without
# refreshing the session snapshot.
if [ "$handoff_mtime" -lt "$head_commit_time" ]; then
  echo '{"continue": false, "stopReason": "HANDOFF.md is older than the most recent commit. Run /handoff before ending the session to capture state for the next session."}'
  exit 0
fi

echo '{"continue": true}'
exit 0
