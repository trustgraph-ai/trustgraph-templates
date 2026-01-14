"""
Integration tests for CLI interface.
"""

import pytest
import subprocess


@pytest.mark.integration
class TestCLIInterface:
    """Tests for CLI command line interface."""

    def test_cli_executable_help(self):
        """Test that CLI executable --help works."""
        result = subprocess.run(
            ['tg-configurator', '--help'],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        assert 'usage' in result.stdout.lower()

    def test_cli_executable_exists(self):
        """Test that tg-configurator is in PATH."""
        result = subprocess.run(
            ['which', 'tg-configurator'],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0

    def test_output_modes(self, run_configurator, test_config_dir):
        """Test -O and -R output modes."""
        config_file = str(test_config_dir / "minimal.json")

        # Test -O mode
        stdout_o, _, code_o = run_configurator([
            '-t', '1.8',
            '-p', 'docker-compose',
            '-i', config_file,
            '--latest-stable',
            '-O'
        ])
        assert code_o == 0
        assert len(stdout_o) > 0

        # Test -R mode
        stdout_r, _, code_r = run_configurator([
            '-t', '1.8',
            '-p', 'docker-compose',
            '-i', config_file,
            '--latest-stable',
            '-R'
        ])
        assert code_r == 0
        assert len(stdout_r) > 0

        # Outputs should be different
        assert stdout_o != stdout_r

    def test_platform_argument(self, run_configurator, test_config_dir):
        """Test -p/--platform argument."""
        config_file = str(test_config_dir / "minimal.json")

        for platform in ['docker-compose', 'minikube-k8s']:
            stdout, stderr, code = run_configurator([
                '-t', '1.8',
                '-p', platform,
                '-i', config_file,
                '--latest-stable',
                '-O'
            ])
            assert code == 0, f"Failed for platform {platform}"

    def test_template_argument(self, run_configurator, test_config_dir):
        """Test -t/--template argument."""
        config_file = str(test_config_dir / "minimal.json")

        for template in ['1.6', '1.7', '1.8']:
            stdout, stderr, code = run_configurator([
                '-t', template,
                '-p', 'docker-compose',
                '-i', config_file,
                '--latest-stable',
                '-O'
            ])
            assert code == 0, f"Failed for template {template}"
