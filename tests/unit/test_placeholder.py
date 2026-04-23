"""Placeholder unit test — ensures CI has a green baseline before real code lands."""

from freedom import __version__


def test_version_is_defined() -> None:
    assert __version__ == "0.1.0"
