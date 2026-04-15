"""
Contract smoke tests on the tg-build-deployment CLI itself. The bulk of
behavioural coverage lives in the API-driven tests (test_components.py,
test_overrides.py, test_launch_shape.py); these run the real CLI as a
subprocess to catch packaging / entrypoint / resource-loading bugs that
the API-level tests can't see.
"""

import json
import shutil
import subprocess
import zipfile

import pytest

from helpers import minimal_config


pytestmark = pytest.mark.features


# Skip the whole module if the CLI isn't installed on PATH. Contract
# smoke tests are explicitly testing the installed entrypoint — if it's
# not there, there's nothing to smoke-test.
CLI = shutil.which("tg-build-deployment")
if CLI is None:
    pytest.skip(
        "tg-build-deployment not on PATH — install the package (pip install .)",
        allow_module_level=True,
    )


def _cli(args, cwd=None):
    return subprocess.run(
        [CLI] + args,
        capture_output=True,
        text=True,
        cwd=cwd,
    )


@pytest.fixture
def cli_workspace(tmp_path):
    """A tmp dir containing a known-good config.json and a place for deploy.zip."""
    config_path = tmp_path / "config.json"
    config_path.write_text(json.dumps(minimal_config([])))
    return tmp_path


class TestCliSmoke:

    def test_help_runs(self):
        """The CLI entrypoint resolves and --help exits cleanly."""
        result = _cli(["--help"])
        assert result.returncode == 0, result.stderr
        assert "usage" in result.stdout.lower()

    def test_build_produces_deploy_zip(self, cli_workspace):
        """Running the CLI against a real config produces a non-empty
        deploy.zip on disk."""
        result = _cli(
            ["-t", "2.3", "-p", "docker-compose",
             "-i", "config.json", "-o", "deploy.zip"],
            cwd=cli_workspace,
        )
        assert result.returncode == 0, (
            f"CLI failed:\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
        zip_path = cli_workspace / "deploy.zip"
        assert zip_path.exists(), "deploy.zip not created"
        assert zip_path.stat().st_size > 0, "deploy.zip is empty"

    def test_deploy_zip_contains_expected_paths(self, cli_workspace):
        """The zip carries docker-compose.yaml, the trustgraph config, and
        at least one launch.yaml — proves resource loading + additionals
        rendering + zip packaging all work end to end."""
        _cli(
            ["-t", "2.3", "-p", "docker-compose",
             "-i", "config.json", "-o", "deploy.zip"],
            cwd=cli_workspace,
        )
        with zipfile.ZipFile(cli_workspace / "deploy.zip") as z:
            names = set(z.namelist())

        assert "docker-compose.yaml" in names
        assert "trustgraph/config.json" in names
        launch_files = [n for n in names if n.endswith("launch.yaml")]
        assert launch_files, (
            f"no launch.yaml files in deploy.zip (contents: {sorted(names)})"
        )

    def test_launch_yaml_inside_zip_is_parseable(self, cli_workspace):
        """Cross-check: the launch.yaml the CLI wrote into the zip is the
        same flavour of YAML the API-level tests parse. Protects against
        encoding / newline / zip-path regressions."""
        import yaml

        _cli(
            ["-t", "2.3", "-p", "docker-compose",
             "-i", "config.json", "-o", "deploy.zip"],
            cwd=cli_workspace,
        )
        with zipfile.ZipFile(cli_workspace / "deploy.zip") as z:
            launch_files = [n for n in z.namelist() if n.endswith("launch.yaml")]
            assert launch_files
            for name in launch_files:
                content = z.read(name).decode("utf-8")
                doc = yaml.safe_load(content)
                assert isinstance(doc, dict), f"{name}: not a mapping"
                assert "processors" in doc, f"{name}: missing processors key"

    def test_bad_platform_fails_nonzero(self, cli_workspace):
        """Sanity: the CLI surfaces failure with non-zero exit code when
        handed a bogus platform."""
        result = _cli(
            ["-t", "2.3", "-p", "not-a-real-platform",
             "-i", "config.json", "-o", "deploy.zip"],
            cwd=cli_workspace,
        )
        assert result.returncode != 0
