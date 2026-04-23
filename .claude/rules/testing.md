---
paths: ["tests/**/*.py"]
---

# Testing rules

## Categories
- `tests/unit/` — per-function, fast (<100ms), deterministic.
- `tests/property/` — Hypothesis-generated invariants. Use `@given` decorator. Seed fixed in CI default job; randomised in nightly.
- `tests/reference/` — loads a fixture from `tests/fixtures/`, runs the pipeline, asserts expected values from the fixture's sidecar `expected.json`.
- `tests/metamorphic/` — assert invariants under data transforms (shift/scale/timezone-rename/reverse). These catch accounting bugs that pass unit tests.
- `tests/integration/` — end-to-end across pipeline stages. Marked with `@pytest.mark.integration`.

## Required for every new pipeline stage
Fixtures and tests must cover:
- no-trade scenario
- single-trade scenario
- many-trade scenario
- bad-data scenario (NaN, negative prices, duplicate timestamps)
- missing-candles scenario (gaps)

## Rules
- Never `==` on floats. Use `pytest.approx(expected, rel=1e-9)`.
- Money uses `Decimal`.
- Fixtures live in `tests/fixtures/<scenario>/` with a sidecar `expected.json`.
- Magic numbers allowed in tests (Ruff `PLR2004` is disabled for `tests/**`).
- `print()` acceptable in tests during debugging but must not be committed.
