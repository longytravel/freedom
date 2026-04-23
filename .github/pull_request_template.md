# Summary

<!-- Plain-English description of what this PR changes. -->

Closes #

## Self-review checklist

Paste the output of the `code-review` skill run on this PR's diff below, then tick each box.

- [ ] Every changed function has a test (unit, property, reference, metamorphic, or integration).
- [ ] No `==` on floats — uses `pytest.approx` or `Decimal`.
- [ ] Money values use `Decimal`, not `float`.
- [ ] Edge cases covered where applicable: no-trade, one-trade, many-trades, bad-data, missing-candles.
- [ ] No `print()` or debug logging left in.
- [ ] No silently-changed parameter defaults. If any default changed, it's called out here.
- [ ] No new `TODO` / `FIXME` comments — opened an issue instead.
- [ ] Spec, CLAUDE.md, and PROGRESS.md updated if the change touches them.
- [ ] An ADR exists under `docs/adr/` for any new domain decision.
- [ ] `uv run pytest` passed locally on all 5 categories.
- [ ] `cargo test` passed locally if Rust was touched.
- [ ] `uv run pre-commit run --all-files` passed locally.

## Code-review output

<!-- Paste skill output here. -->
