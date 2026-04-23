"""Placeholder metamorphic test — real invariants added alongside the first pipeline stage."""

from hypothesis import given
from hypothesis import strategies as st


@given(st.lists(st.integers(min_value=-1000, max_value=1000), min_size=1, max_size=50))
def test_sum_invariant_under_reversal(xs: list[int]) -> None:
    # Baseline metamorphic pattern: a transform that must preserve a property.
    assert sum(xs) == sum(reversed(xs))
