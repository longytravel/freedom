"""Placeholder reference test — real fixtures added alongside the first pipeline stage."""

from decimal import Decimal

import pytest


def test_decimal_money_arithmetic() -> None:
    # Baseline: Decimal money stays exact. Enforces CLAUDE.md rule.
    a = Decimal("0.10")
    b = Decimal("0.20")
    assert a + b == Decimal("0.30")


def test_never_use_equals_on_floats() -> None:
    # Baseline: approx comparison pattern the rest of the suite must follow.
    # noqa rationale: pytest.approx on RHS is the idiomatic form; SIM300 would
    # force Yoda-style which conflicts with pytest docs.
    assert 0.1 + 0.2 == pytest.approx(0.3, rel=1e-9)  # noqa: SIM300
