"""Placeholder property test — ensures hypothesis is wired into CI."""

from hypothesis import given
from hypothesis import strategies as st


@given(st.integers(min_value=0, max_value=1_000_000))
def test_non_negative_integers_stay_non_negative(n: int) -> None:
    assert n + 1 > 0
