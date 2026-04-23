#!/usr/bin/env bash
# PostToolUse hook: auto-format Python files that were just edited by the agent.
# Uses Python to parse JSON stdin (no jq dependency). Silent on failure — never blocks.

set -u
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

file_path=$(python - <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(sys.stdin)
    p = d.get("tool_response", {}).get("filePath") or d.get("tool_input", {}).get("file_path", "")
    print(p)
except Exception:
    pass
PY
)

case "$file_path" in
  *.py)
    uv run ruff check --fix "$file_path" >/dev/null 2>&1 || true
    uv run ruff format "$file_path" >/dev/null 2>&1 || true
    ;;
esac

exit 0
