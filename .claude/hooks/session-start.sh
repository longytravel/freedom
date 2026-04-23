#!/usr/bin/env bash
# SessionStart hook: loads HANDOFF.md and PROGRESS.md into the new session's
# context so the agent always starts from the last known state. If this does
# not fire, the session drifts from the truth in git. Non-blocking.

set -u
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || { echo '{}'; exit 0; }

LOG=".claude/hooks/log.txt"
mkdir -p .claude/hooks
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) session-start-hook fired" >> "$LOG" 2>/dev/null || true

HANDOFF_TEXT="_HANDOFF.md not found_"
PROGRESS_TEXT="_PROGRESS.md not found_"
[ -f HANDOFF.md ] && HANDOFF_TEXT=$(cat HANDOFF.md)
[ -f PROGRESS.md ] && PROGRESS_TEXT=$(cat PROGRESS.md)

RECENT_COMMITS=$(git log --oneline -10 2>/dev/null || echo "_not a git repo_")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "_unknown_")
STATUS=$(git status --short 2>/dev/null || echo "")

CONTEXT=$(cat <<SESSION_START_EOF
# Session start — paperwork snapshot

**Current branch:** ${CURRENT_BRANCH}

## HANDOFF.md

${HANDOFF_TEXT}

## PROGRESS.md

${PROGRESS_TEXT}

## Recent commits (git log --oneline -10)

\`\`\`
${RECENT_COMMITS}
\`\`\`

## Uncommitted changes (git status --short)

\`\`\`
${STATUS:-"(clean)"}
\`\`\`

---

If HANDOFF.md says mid-stream work is in progress, **finish it before starting anything new**.
SESSION_START_EOF
)

# Emit JSON with additionalContext. Use python for safe JSON escaping.
if command -v python >/dev/null 2>&1; then
  printf '%s' "$CONTEXT" | python -c "import json,sys; print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': sys.stdin.read()}}))"
elif command -v python3 >/dev/null 2>&1; then
  printf '%s' "$CONTEXT" | python3 -c "import json,sys; print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': sys.stdin.read()}}))"
else
  # Fallback: emit empty object rather than malformed JSON.
  echo '{}'
fi

exit 0
