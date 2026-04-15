"""
Pytest plumbing for feature-contract tests. Helpers live in helpers.py so
they can be imported directly by test modules.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))

from helpers import build as _build


@pytest.fixture
def build():
    """Run Packager on a config list and return (compose, launches)."""
    return _build
