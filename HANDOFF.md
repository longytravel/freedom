# Handoff — 2026-04-23

**Branch:** feat/harden-workbench-hooks-and-protection
**Status:** Mid-flight. Hardening the workbench harness itself — the Codex review flagged that the Stop hook was a no-op, branch protection was never applied, and the PR checklist was honour-system. Fixing all of that in this branch before any Freedom-domain work begins.

## Goal
Turn the scaffold into an actual quality gate. Five changes in this branch:
1. Stop hook now blocks session end when HANDOFF.md is older than the last commit.
2. New SessionStart hook injects HANDOFF.md + PROGRESS.md + recent commits into every new session so drift is impossible.
3. Tightened deny list in `.claude/settings.json` — blocks `--no-verify`, force push anywhere, amends, hard resets, direct `git checkout main`, and admin PR merges.
4. New `pr-checklist` CI workflow fails a PR if the summary placeholder or code-review output placeholder is still present, or if zero self-review items are ticked.
5. Branch protection on `main` applied via `gh api` (required status checks: python, rust, pr-checklist; no force pushes; linear history; conversation resolution required).

## Completed this session
- Codex review (gpt-5.4 / high reasoning) of the whole workbench — verdict: "No as-is" without hard gates.
- Scoped the fix list to harness-only (forex-domain gaps explicitly deferred).
- Rewrote `.claude/hooks/update-paperwork.sh` to block stop when paperwork is stale.
- Added `.claude/hooks/session-start.sh` for pre-flight context injection.
- Tightened `.claude/settings.json` deny list and registered the SessionStart hook.
- Added `.github/workflows/pr-checklist.yml`.

## Not yet done
- Commit + push this branch.
- Open the PR with the self-review output pasted in (to prove the new checklist workflow passes).
- Run the `gh api` call that applies branch protection on `main`.
- Merge this PR (squash) and delete the branch.

## Failed approaches — DON'T REPEAT
- Shipping a Stop hook that only checked `HANDOFF.md` existed and was <60 min old — it never rewrote anything, never blocked anything, and let PR #14+ land without refreshing the handoff. Anti-drift enforcement must compare handoff mtime to the last commit time, not the wall clock.
- Relying on the PR template checklist as pure honour-system — it will be skipped. Machine-check at least the placeholders.

## Exact resume steps for next session
1. Read this file and `PROGRESS.md` (the SessionStart hook will have already surfaced them).
2. If this branch isn't merged yet: finish it. Check PR status with `gh pr status`, address any CI failures, request merge once CodeRabbit + Gemini have commented.
3. Once merged: delete the local branch, verify branch protection is active via `gh api repos/longytravel/freedom/branches/main/protection`, and update PROGRESS.md to tick "Branch protection applied".
4. Then (and only then) start the first Freedom subsystem spec — data ingest is the natural first slice.
