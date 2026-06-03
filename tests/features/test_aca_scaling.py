"""
Regression tests for replica-count wiring in the ACA (Azure Container Apps)
engine.

The *-replicas override params are honoured by the compose/k8s engines, but
the ACA engine used to ignore them: containerSet.with_replicas was a no-op
and every containerApp hardcoded scale.minReplicas / maxReplicas to 1. These
tests render the ARM template and assert the override now reaches each app's
scale block (min and max pinned to the count, matching k8s fixed-replica
semantics).

Rendered at template 2.5 / platform "aca" directly - the shared helper's
run_packager is pinned to 2.3 / docker-compose.
"""

import json

import pytest

from helpers import minimal_config
from trustgraph_configurator.packager import Packager


pytestmark = pytest.mark.features


TEMPLATE = "2.5"
VERSION = "2.5.10"


def render_aca(config):
    """Render a config list to the ACA ARM template (a dict)."""
    pkg = Packager(
        version=VERSION,
        template=TEMPLATE,
        platform="aca",
        latest=False,
        latest_stable=False,
    )
    config_str = json.dumps(config)
    pkg.config = config_str
    return pkg.generate_resources(config_str)


def scale_by_app(arm):
    """Map containerApp name -> its template.scale block."""
    return {
        r["name"]: r["properties"]["template"]["scale"]
        for r in arm["resources"]
        if r.get("type") == "Microsoft.App/containerApps"
    }


# (replica override param, containerApp name)
CASES = [
    ("control-replicas", "control"),
    ("triples-replicas", "triples"),
    ("rows-replicas", "rows"),
]


@pytest.mark.parametrize("param,app", CASES, ids=[c[1] for c in CASES])
def test_default_replicas_is_one(param, app):
    """Without an override, each app pins min/max replicas to 1."""
    scales = scale_by_app(render_aca(minimal_config([])))
    assert scales[app] == {"minReplicas": 1, "maxReplicas": 1}


@pytest.mark.parametrize("param,app", CASES, ids=[c[1] for c in CASES])
def test_replica_override_applies(param, app):
    """An override flows through to the app's scale.min/maxReplicas."""
    scales = scale_by_app(render_aca(minimal_config([], overrides={param: 3})))
    assert scales[app] == {"minReplicas": 3, "maxReplicas": 3}


def test_override_is_scoped_to_one_app():
    """Overriding one app's replicas leaves the others at the default."""
    scales = scale_by_app(
        render_aca(minimal_config([], overrides={"control-replicas": 4}))
    )
    assert scales["control"] == {"minReplicas": 4, "maxReplicas": 4}
    assert scales["triples"] == {"minReplicas": 1, "maxReplicas": 1}
    assert scales["rows"] == {"minReplicas": 1, "maxReplicas": 1}
