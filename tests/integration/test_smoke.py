"""End-to-end smoke test placeholder — asserts the package is importable as a whole."""

import pytest

import freedom


@pytest.mark.integration
def test_package_importable() -> None:
    assert hasattr(freedom, "__version__")
