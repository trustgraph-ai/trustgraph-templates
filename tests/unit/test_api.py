"""
Unit tests for API module.
"""

import pytest
from trustgraph_configurator import api


@pytest.mark.unit
class TestAPI:
    """Tests for the API module."""

    def test_get_templates_returns_list(self):
        """Test that get_templates returns a list."""
        templates = api.get_templates()
        assert isinstance(templates, list)
        assert len(templates) > 0

    def test_templates_have_required_fields(self):
        """Test that templates have name and version fields."""
        templates = api.get_templates()
        for template in templates:
            assert hasattr(template, 'name')
            assert hasattr(template, 'version')

    def test_get_latest_returns_template(self):
        """Test that get_latest returns a template."""
        latest = api.get_latest()
        assert latest is not None
        assert hasattr(latest, 'name')
        assert hasattr(latest, 'version')

    def test_get_latest_stable_returns_template(self):
        """Test that get_latest_stable returns a template."""
        latest_stable = api.get_latest_stable()
        assert latest_stable is not None
        assert hasattr(latest_stable, 'name')
        assert hasattr(latest_stable, 'version')
