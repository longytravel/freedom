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

# Freshness check via git history, not filesystem mtime. File mtime can be
# seconds older than commit time even when the file is part of that same
# commit, which previously caused false-positive blocks.
#
# HANDOFF.md is considered fresh if EITHER:
#   - it has uncommitted (staged or unstaged) modifications, OR
#   - there are zero commits since the most recent commit that touched it
#     (i.e., it was updated in the last commit or nothing has changed since).
head_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
last_handoff_commit=$(git log -1 --format=%H -- HANDOFF.md 2>/dev/null || echo "")
handoff_uncommitted=$(git status --porcelain -- HANDOFF.md 2>/dev/null | wc -l | tr -d ' ')

if [ -z "$last_handoff_commit" ] && [ "${handoff_uncommitted:-0}" -eq 0 ]; then
  echo '{"continue": false, "stopReason": "HANDOFF.md is untracked and unmodified. Commit it or run /handoff before ending the session."}'
  exit 0
fi

commits_since_handoff=0
if [ -n "$last_handoff_commit" ] && [ -n "$head_commit" ]; then
  commits_since_handoff=$(git rev-list --count "${last_handoff_commit}..${head_commit}" 2>/dev/null || echo 0)
  commits_since_handoff=$(echo "$commits_since_handoff" | tr -d ' ')
fi

# Uncommitted changes outside paperwork. `cut -c4-` is safe for paths with
# spaces; `awk '{print $NF}'` would only grab the last whitespace-separated token.
# `.claude/scheduled_tasks.lock` is runtime state from the ScheduleWakeup system.
uncommitted=$(git status --porcelain 2>/dev/null \
  | cut -c4- \
  | grep -v '^HANDOFF\.md$' \
  | grep -v '^PROGRESS\.md$' \
  | grep -v '^\.claude/hooks/log\.txt$' \
  | grep -v '^\.claude/scheduled_tasks\.lock$' \
  | wc -l | tr -d ' ')

# Block: real uncommitted work exists and HANDOFF.md has neither uncommitted
# edits nor was touched in the latest commits.
if [ "${uncommitted:-0}" -gt 0 ] && [ "${handoff_uncommitted:-0}" -eq 0 ] && [ "${commits_since_handoff:-0}" -gt 0 ]; then
  echo '{"continue": false, "stopReason": "Uncommitted changes exist and HANDOFF.md is older than the latest commit. Run /handoff before ending the session so the next session knows where to resume."}'
  exit 0
fi

# Block: commits landed since HANDOFF.md was last refreshed and the current
# HANDOFF.md has no fresh edits waiting to be committed.
if [ "${handoff_uncommitted:-0}" -eq 0 ] && [ "${commits_since_handoff:-0}" -gt 0 ]; then
  echo '{"continue": false, "stopReason": "HANDOFF.md is older than the most recent commit. Run /handoff before ending the session to capture state for the next session."}'
  exit 0
fi

echo '{"continue": true}'
exit 0
