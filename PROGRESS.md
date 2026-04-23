# Progress

Living checklist of milestones. Tick items as they ship.

## Workbench

- [x] Repo initialised
- [x] Development-workflow spec written (`docs/superpowers/specs/2026-04-23-dev-workflow-setup-design.md`)
- [x] Initial commit on main pushed
- [x] First CI run green
- [ ] Branch protection applied
- [x] Gemini Code Assist installed (free, 33 reviews/day quota)
- [x] CodeRabbit active on public repo (free forever for public repos)
- [x] First real PR (#11) merged — full loop proved end-to-end
- [ ] Stop hook actually blocks when HANDOFF.md is stale (was a no-op before)
- [ ] SessionStart hook injects paperwork into every new session
- [ ] PR-checklist CI job fails on empty placeholders / no ticked boxes

## Freedom platform — subsystems (future)

Each line below is a placeholder for a future spec + implementation cycle.

- [ ] Data ingest (Dukascopy M1)
- [ ] Data quality checks + resample
- [ ] Spread / commission / slippage model
- [ ] Signal plugin interface
- [ ] Exit plugin interface
- [ ] Filter plugin interface
- [ ] Position sizing plugin interface
- [ ] Rust backtest engine (first functional code)
- [ ] Python ↔ Rust bridge (pyo3 + maturin)
- [ ] Optimiser interface (random / grid / Bayesian / genetic)
- [ ] Walk-forward validation
- [ ] Monte Carlo / robustness
- [ ] Parity harness (backtest vs live)
- [ ] Experiment tracker
- [ ] Web UI — signal builder, results dashboard
- [ ] VPS live runner
- [ ] Live monitoring + reconciliation
