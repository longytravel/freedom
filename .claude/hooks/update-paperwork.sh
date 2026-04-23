#!/usr/bin/env bash
# Stop hook: refuses to end the session if uncommitted code changes exist but
# HANDOFF.md was not updated recently. Belt-and-braces with the self-review checklist.
# 5-second timeout. Always exits cleanly.

set -u
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || { echo '{"continue": true}'; exit 0; }

LOG=".claude/hooks/log.txt"
mkdir -p .claude/hooks
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) stop-hook fired" >> "$LOG" 2>/dev/null || true

# If not a git repo yet, allow stop.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"continue": true}'
  exit 0
fi

# If nothing changed vs HEAD, everything's in history — fine to stop.
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  echo '{"continue": true}'
  exit 0
fi

# Uncommitted changes exist. Require HANDOFF.md to exist and be fresh.
if [ ! -f HANDOFF.md ]; then
  cat <<'EOF'
{"continue": false, "stopReason": "Uncommitted changes exist but HANDOFF.md is missing. Run /handoff before ending the session."}
EOF
  exit 0
fi

now=$(date +%s)
mtime=$(stat -c %Y HANDOFF.md 2>/dev/null || stat -f %m HANDOFF.md 2>/dev/null || echo 0)
age_min=$(( (now - mtime) / 60 ))

if [ "$age_min" -gt 60 ]; then
  printf '{"continue": false, "stopReason": "Uncommitted changes exist but HANDOFF.md was last updated %s minutes ago. Run /handoff before ending the session."}\n' "$age_min"
  exit 0
fi

echo '{"continue": true}'
exit 0
