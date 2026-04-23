# Handoff — 2026-04-23

**Branch:** feat/harden-workbench-hooks-and-protection
**Status:** All required CI checks green on PR #16. CodeRabbit + Gemini follow-up review in progress on the fix commit. Branch protection on `main` is **live** (`enforce_admins: false`). Ready to squash-merge once bot follow-up lands with no new blockers.

## Goal
Turn the scaffold into an actual quality gate. Five harness-only fixes + branch protection on `main`.

## Completed this session
- Codex (gpt-5.4 high) review of the workbench — verdict was "No as-is" without hard gates.
- Rewrote the Stop hook so it compares HANDOFF.md mtime to the last commit time. **Confirmed working** — blocked this very session when I committed without refreshing HANDOFF.md first.
- Added SessionStart hook to inject HANDOFF.md + PROGRESS.md + recent commits at session open.
- Tightened settings.json deny list: --no-verify, force push, amends, resets, direct `checkout main`, admin PR merges, branch-protection deletion.
- Added pr-checklist CI workflow that fails on unreplaced placeholders or missing/empty checklists.
- Addressed all five real issues flagged by CodeRabbit + Gemini on the first commit (2× security-rated deny-pattern bypasses, 1× checklist-workflow bypass, 2× shell-fragility, 1× unsafe heredoc).
- **Branch protection live** on `main`: required checks python/rust/checklist/gitleaks, strict, linear history, no force-push, no delete, conversation resolution required. `enforce_admins: false` retained as emergency override per user decision.

## Not yet done
- Wait for CodeRabbit and Gemini to re-review commit `5183e55` (the fix commit).
- If no new blockers, squash-merge PR #16 and delete the local + remote branch.
- Start the first Freedom subsystem spec — data ingest is the natural first slice.

## Failed approaches — DON'T REPEAT
- Original Stop hook only checked HANDOFF.md was <60 min old and never rewrote anything. Caused drift from session 2 onward. Anti-drift enforcement must compare handoff mtime to the last commit time.
- Honour-system PR checklist — skipped almost immediately. Machine-check placeholders and require at least one ticked box, with the section bounded between its heading and the next `##`.
- `git push -f *` with a trailing space before `*` — left a bypass (matches `git push -f something` but not `git push -f`). Use `-f*` with no space.
- `awk '{print $NF}'` on `git status --porcelain` — breaks on paths with spaces. Use `cut -c4-` for the fixed-width porcelain layout.
- Parsing Claude Code hook JSON with `grep` — fragile across whitespace. Use `python -c json.load`.
- Unquoted `EOF` heredocs in hooks — any `EOF` line in HANDOFF.md would terminate the heredoc early. Use a unique delimiter.

## Exact resume steps for next session
1. Read this file and PROGRESS.md (SessionStart hook surfaces them automatically).
2. If PR #16 isn't merged yet: `gh pr checks 16` — all four required checks must be green. Check `gh api repos/longytravel/freedom/pulls/16/comments` for any new CodeRabbit/Gemini comments on commit `5183e55`. Resolve or address, then squash-merge.
3. After merge: `git checkout main && git pull && git branch -d feat/harden-workbench-hooks-and-protection` and `git push origin --delete feat/harden-workbench-hooks-and-protection`.
4. Then start the first Freedom subsystem spec — data ingest is the natural first slice. Use `superpowers:brainstorming` first, then write the spec under `docs/superpowers/specs/`, then open a branch `feat/<issue>-data-ingest`.
