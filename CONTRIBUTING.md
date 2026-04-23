# Contributing

This repo is built primarily by an AI agent (Claude Code) working in sessions with a non-coder operator. The workflow below is mandatory.

## Workflow

1. **New feature / fix starts with a spec** under `docs/superpowers/specs/YYYY-MM-DD-<topic>.md`.
2. **Create an issue** describing the work: `gh issue create`.
3. **Branch from `main`:** `feat/<issue>-<slug>` or `fix/<issue>-<slug>`.
4. **Red → green → refactor.** Failing test first, then implementation.
5. **Pre-commit runs automatically** on every `git commit`. If it fails, fix and re-commit.
6. **Self-review the diff** using the `code-review` skill. Paste output into the PR body.
7. **Open the PR** with `gh pr create --fill`.
8. **Wait for CI green** and the Gemini Code Assist advisory review comment. Address anything concerning.
9. **Squash-merge** with `gh pr merge --squash --delete-branch`.

## Branch rules (enforced by GitHub)

- No direct pushes to `main`.
- PR required.
- All CI checks must be green.
- Linear history.
- Admins included — escape hatch documented in the design spec.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/):

- `feat(scope): add X`
- `fix(scope): correct Y`
- `chore: ...`, `docs: ...`, `test: ...`, `refactor: ...`

Body references the issue: `Closes #42`.

## Testing requirement

Every code change ships with a test in the appropriate category:

- `tests/unit/` — per-function.
- `tests/property/` — Hypothesis-generated invariants.
- `tests/reference/` — expected-value assertions on fixed market fixtures.
- `tests/metamorphic/` — invariants under data transforms (shift, scale, timezone).
- `tests/integration/` — end-to-end pipeline smoke.

Never `==` on floats. Use `pytest.approx` or `Decimal`.

## Domain decisions

Anything that is a modelling choice (timezone, calendar, spread model, slippage, commission) gets an ADR in `docs/adr/NNNN-*.md`. No silent defaults.
