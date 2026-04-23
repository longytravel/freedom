---
paths: ["**/*.py"]
---

# Python style rules

## Hard rules
- Never compare floats with `==`. Use `pytest.approx(expected, rel=1e-9)` in tests or explicit tolerances in code.
- Money is `decimal.Decimal`, never `float`.
- All public functions in `src/` have full type hints (enforced by `mypy --strict`).
- No `print()` in `src/` — use `logging`.
- No bare `except:` — name the exception.

## Soft preferences
- Prefer `dataclasses` over bare dicts for domain models.
- Prefer `pathlib.Path` over string paths.
- Imports sorted by `ruff` automatically.

## Forbidden patterns
- Global mutable state.
- Monkey-patching.
- Dynamic `exec` / `eval`.
