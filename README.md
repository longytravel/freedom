# Freedom

Forex strategy research, optimisation and deployment platform.

## What this is

A disciplined development workbench for building a forex backtest / live trading system. Everything is PR-driven, tested before merge, and auto-documented as work progresses.

## Status

Workbench live. Freedom subsystem specs begin next.

## Layout

- `src/freedom/` — Python orchestration
- `core/` — Rust backtest engine (empty stub; added in a later PR)
- `tests/` — five categories: unit, property, reference, metamorphic, integration
- `docs/superpowers/specs/` — feature specifications
- `docs/adr/` — architecture decision records
- `.claude/` — agent rules, hooks, and slash commands
- `.github/workflows/` — CI pipelines

## Working in this repo

If you're the agent working here: read `CLAUDE.md` first, then check `HANDOFF.md` for current state.

If you're a human: open a pull request for every change. Merges to `main` require every CI check green.
