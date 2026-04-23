# Test fixtures

Deterministic sample datasets used by `tests/reference/` and `tests/metamorphic/`.

## Conventions

- One folder per scenario: `eurusd_m1_2024_03_sample/`, `gbpusd_news_day/`, etc.
- Each folder contains the raw CSV/parquet **and** a sidecar `expected.json` with the trade list, equity curve, fees, PnL that the backtest must reproduce.
- Fixtures are **small** (a few thousand bars max) so tests run fast.
- Commit fixtures with the PR that uses them.

## Adding a fixture

1. Create the folder under `tests/fixtures/`.
2. Write the data file(s).
3. Write `expected.json` — compute by hand or by the first reference implementation.
4. Write a test under `tests/reference/` that loads the fixture, runs the backtest, and asserts every field in `expected.json`.
