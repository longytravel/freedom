# Handoff — 2026-04-23

**Branch:** feat/harden-workbench-hooks-and-protection
**Status:** PR #16 open. CodeRabbit + Gemini reviewed and between them found 5 real bugs (two security-rated deny-pattern bypasses, a checklist-workflow bypass, two shell-fragility bugs, an unsafe heredoc). All five fixed in a follow-up commit. Branch protection not yet applied (awaiting user decision on `enforce_admins`).

## Goal
Turn the scaffold into an actual quality gate — five harness-only fixes landing as one PR, then branch protection applied via `gh api`.

## Completed this session
- Codex (gpt-5.4 high) reviewed the whole workbench; verdict was "No as-is" without hard gates.
- Scoped the fix list to harness-only (forex-domain gaps explicitly deferred until the project starts).
- Rewrote `.claude/hooks/update-paperwork.sh` — Stop hook now compares HANDOFF.md mtime to the last commit time instead of wall-clock. Confirmed working: it blocked this very session when commits landed without refreshing the handoff.
- Added `.claude/hooks/session-start.sh` — injects HANDOFF.md + PROGRESS.md + recent commits into every new session.
- Tightened `.claude/settings.json` deny list (--no-verify, force push anywhere, amends, resets, direct checkout of main, admin merges, branch-protection deletion).
- Added `.github/workflows/pr-checklist.yml` — machine-checks PR body for placeholders and unticked checklists. Confirmed working on PR #16 (passed in 4s).
- Pushed branch, opened PR #16 with full self-review filled in.
- PR #16 status: `python`, `rust`, `checklist`, `gitleaks` all green; `CodeQL` and `CodeRabbit` pending; Gemini review pending.

## Not yet done
- Apply branch protection on `main` via `gh api` — user chose `enforce_admins: false` (retain emergency override). Blocked pending execution.
- Wait for CodeRabbit + Gemini review comments on PR #16; address anything they flag.
- Squash-merge PR #16, delete local branch.
- Tick "Branch protection applied" in PROGRESS.md after the `gh api` call succeeds.

## Failed approaches — DON'T REPEAT
- Shipping a Stop hook that only checked HANDOFF.md existed and was <60 min old — it never rewrote anything and let every post-first session silently drift. Anti-drift enforcement must compare handoff mtime to the last commit time, not the wall clock.
- Relying on the PR template checklist as pure honour-system. Machine-check at least the placeholders.

## Exact resume steps for next session
1. Read this file and PROGRESS.md (the SessionStart hook will surface them automatically).
2. If PR #16 isn't merged yet: check `gh pr status` and `gh pr checks 16`; address any CodeRabbit/Gemini comments; request squash-merge when green.
3. After merge: run the branch-protection `gh api` call (JSON saved in the PR body); verify via `gh api repos/longytravel/freedom/branches/main/protection | head -30`; tick "Branch protection applied" in PROGRESS.md.
4. Only then move to the first Freedom subsystem spec — data ingest is the natural first slice.
