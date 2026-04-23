# Freedom — Agent Instructions

The user is **not a coder**. The system is the quality gate, not them. Every rule below exists because of that fact.

## How to talk to the user
- Plain English only. No shell commands, yaml/json, or file paths in chat.
- One short sentence before acting (what you're about to do) and one short sentence after (what happened).
- Put technical detail in files and tool calls, never in the conversation.
- Max 5 plain-English bullets when presenting a plan or a choice.

## Before writing any code
1. Invoke `superpowers:brainstorming` on any new work.
2. If a spec doesn't exist, write one under `docs/superpowers/specs/`.
3. Summarise the plan in plain English and get user approval before executing.

## While coding
1. One feature = one branch: `feat/<issue-number>-<slug>`.
2. Write a failing test first. (`superpowers:test-driven-development`.)
3. Make it pass.
4. `pre-commit` runs on every commit; fix any failures.
5. Conventional Commits for messages.

## Completing work
1. Invoke `superpowers:verification-before-completion` before claiming done.
2. All five test categories must pass locally.
3. Run the `code-review` skill on the diff; paste output in the PR body.
4. Open PR; wait for green CI + advisory review comments from both CodeRabbit and Gemini Code Assist. Address anything they flag before merge.
5. Squash-merge, delete branch.

## Forbidden
- Committing to `main` directly.
- `git push --force` anywhere.
- Claiming "done" without evidence.
- Adding features not in the approved spec.
- Shipping code without tests.
- Comparing floats with `==`. Use `pytest.approx` or `Decimal`.
- Holding money in `float`. Use `Decimal`.
- Pasting shell commands or long code blocks into chat with the user.

## Domain-decision rule
Every domain choice (timezone, calendar, spread model, slippage, commission, PnL convention, broker execution) gets an ADR under `docs/adr/NNNN-*.md` and is indexed in `docs/adr/README.md`. No domain choice lives only in code.

## Edge cases required for any pipeline-stage work
Every new data loader / signal / filter / executor must have fixtures and tests for: no-trade, one-trade, many-trade, bad-data, missing-candles.

## Session state
- `HANDOFF.md` is **overwritten** every session by the Stop hook (or `/handoff` on demand).
- `PROGRESS.md` is a **living checklist**; tick milestones off, don't rewrite.
- Read both at session start. If `HANDOFF.md` says "in the middle of X", finish X before anything new.

## Root CLAUDE.md discipline
This file stays under 150 lines **forever**.
- New universal rule → may go here, think twice.
- Path-scoped rule → add under `.claude/rules/<topic>.md` with `paths:` frontmatter. Never here.
- Domain fact → write an ADR. Never in the rule layer.
