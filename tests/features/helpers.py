"""
Helpers shared across feature-contract tests. Kept separate from
conftest.py so the names can be imported directly (pytest conftest files
are not importable by name).
"""

import json
import yaml

from trustgraph_configurator.packager import Packager


TEMPLATE = "2.3"
VERSION = "2.3.10"

# Baseline components required to make any feature compile. A full
# TrustGraph deployment needs a pubsub, the core, an LLM, embeddings, and
# storage backends — the runtime-config generator references all of them.
# Tests that want to exercise a different LLM / store / pubsub can pass
# replacement components to minimal_config(); the BASELINE is the default.
BASELINE = [
    "rabbitmq",
    "trustgraph-base",
    "openai",
    "embeddings-fastembed",
    "triple-store-cassandra",
    "row-store-cassandra",
    "vector-store-qdrant",
]


def _entry(name, parameters=None):
    return {"name": name, "parameters": parameters or {}}


def minimal_config(components, overrides=None, without=None):
    """Build a config list containing the baseline plus `components`.

    `components` is a list of either plain component names or already-built
    entries (dicts with 'name'/'parameters'). `without` is an optional list
    of baseline component names to omit (useful when swapping the default
    LLM / store for a different one under test). `overrides` is an optional
    dict of key/value pairs that land in a trailing 'override' entry.
    """
    omit = set(without or [])
    config = [_entry(name) for name in BASELINE if name not in omit]
    for c in components:
        if isinstance(c, dict):
            config.append(c)
        else:
            config.append(_entry(c))
    if overrides:
        config.append(_entry("override", overrides))
    return config


def run_packager(config, platform="docker-compose"):
    pkg = Packager(
        version=VERSION,
        template=TEMPLATE,
        platform=platform,
        latest=False,
        latest_stable=False,
    )
    config_str = json.dumps(config)
    pkg.config = config_str
    compose = pkg.generate_resources(config_str)
    additionals = pkg.generate_additionals(config_str)
    return compose, additionals


def extract_launches(additionals):
    launches = {}
    for item in additionals:
        parts = item["path"].split("/")
        if len(parts) == 3 and parts[0] == "launch" and parts[2] == "launch.yaml":
            launches[parts[1]] = yaml.safe_load(item["content"])
    return launches


def build(config, platform="docker-compose"):
    """Run Packager on a config list and return (compose, launches)."""
    compose, additionals = run_packager(config, platform)
    return compose, extract_launches(additionals)


def find_processor(launch_doc, processor_id):
    """Return the first processor in a launch.yaml with the given id."""
    for p in launch_doc.get("processors", []):
        if p.get("params", {}).get("id") == processor_id:
            return p
    raise KeyError(f"processor id={processor_id!r} not found in launch doc")
