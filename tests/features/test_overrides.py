"""
Override-coverage tests. For each declared parameter across the template
tree, assert that:
  (a) the default value lands in the expected place in the generated
      output, and
  (b) an 'override' entry in the config propagates the new value to the
      same place.

These tests are the failsafe against silent regressions in the
override → parameters +:: → $.parameters[...] pipeline.
"""

import pytest

from helpers import minimal_config, find_processor


pytestmark = pytest.mark.features


# ---------------------------------------------------------------------------
# Extractors: given (compose, launches), return the value that a particular
# parameter should end up at.
# ---------------------------------------------------------------------------

def _launch_param(group, processor_id, param_name):
    def _extract(compose, launches):
        return find_processor(launches[group], processor_id)["params"][param_name]
    return _extract


def _service_limit(service, kind):
    """Read compose cpu/memory limit. kind in {cpu-limit, cpu-reservation,
    memory-limit, memory-reservation}."""
    def _extract(compose, launches):
        resources = compose["services"][service]["deploy"]["resources"]
        section, field = {
            "cpu-limit": ("limits", "cpus"),
            "cpu-reservation": ("reservations", "cpus"),
            "memory-limit": ("limits", "memory"),
            "memory-reservation": ("reservations", "memory"),
        }[kind]
        return resources[section][field]
    return _extract


# ---------------------------------------------------------------------------
# Test matrix: (param-key, default, override-value, extractor)
# ---------------------------------------------------------------------------

CASES = [
    # --- ingest concurrency ---
    ("prompt-concurrency", 1, 7,
     _launch_param("ingest", "prompt", "concurrency")),
    ("kg-extract-definitions-concurrency", 1, 3,
     _launch_param("ingest", "kg-extract-definitions", "concurrency")),
    ("kg-extract-ontology-concurrency", 1, 4,
     _launch_param("ingest", "kg-extract-ontology", "concurrency")),
    ("kg-extract-relationships-concurrency", 1, 5,
     _launch_param("ingest", "kg-extract-relationships", "concurrency")),
    ("kg-extract-rows-concurrency", 1, 6,
     _launch_param("ingest", "kg-extract-rows", "concurrency")),

    # --- ingest container resources ---
    ("ingest-cpu-limit", "0.5", "2.0",
     _service_limit("ingest", "cpu-limit")),
    ("ingest-cpu-reservation", "0.1", "1.0",
     _service_limit("ingest", "cpu-reservation")),
    ("ingest-memory-limit", "256M", "1G",
     _service_limit("ingest", "memory-limit")),
    ("ingest-memory-reservation", "256M", "512M",
     _service_limit("ingest", "memory-reservation")),

    # --- rag graph-rag params ---
    ("graph-rag-concurrency", 1, 3,
     _launch_param("rag", "graph-rag", "concurrency")),
    ("graph-rag-entity-limit", 50, 99,
     _launch_param("rag", "graph-rag", "entity_limit")),
    ("graph-rag-triple-limit", 30, 77,
     _launch_param("rag", "graph-rag", "triple_limit")),
    ("graph-rag-edge-limit", 30, 45,
     _launch_param("rag", "graph-rag", "edge_limit")),
    ("graph-rag-edge-score-limit", 10, 25,
     _launch_param("rag", "graph-rag", "edge_score_limit")),
    ("graph-rag-max-subgraph-size", 100, 250,
     _launch_param("rag", "graph-rag", "max_subgraph_size")),
    ("graph-rag-max-path-length", 2, 4,
     _launch_param("rag", "graph-rag", "max_path_length")),

    # --- rag document-rag + prompt-rag ---
    ("document-rag-doc-limit", 20, 100,
     _launch_param("rag", "document-rag", "doc_limit")),
    ("prompt-rag-concurrency", 1, 8,
     _launch_param("rag", "prompt-rag", "concurrency")),

    # --- rag container resources ---
    ("rag-cpu-limit", "0.5", "3.0", _service_limit("rag", "cpu-limit")),
    ("rag-memory-limit", "256M", "768M",
     _service_limit("rag", "memory-limit")),

    # --- embeddings ---
    ("embeddings-concurrency", 1, 4,
     _launch_param("embeddings", "embeddings", "concurrency")),
    ("embeddings-cpu-limit", "4.0", "8.0",
     _service_limit("embeddings", "cpu-limit")),
    ("embeddings-memory-limit", "640M", "1G",
     _service_limit("embeddings", "memory-limit")),

    # --- llm (openai is in baseline) ---
    ("text-completion-concurrency", 1, 5,
     _launch_param("text-completion", "text-completion", "concurrency")),
    ("text-completion-rag-concurrency", 1, 2,
     _launch_param("text-completion", "text-completion-rag", "concurrency")),
    ("text-completion-cpu-limit", "0.5", "2.5",
     _service_limit("text-completion", "cpu-limit")),
    ("text-completion-memory-limit", "128M", "512M",
     _service_limit("text-completion", "memory-limit")),

    # --- stores ---
    ("rows-cpu-limit", "0.5", "2.0",
     _service_limit("rows", "cpu-limit")),
    ("rows-memory-limit", "512M", "1G",
     _service_limit("rows", "memory-limit")),
    ("triples-cpu-limit", "0.5", "2.0",
     _service_limit("triples", "cpu-limit")),
    ("triples-memory-limit", "512M", "1G",
     _service_limit("triples", "memory-limit")),
    ("vector-store-cpu-limit", "0.5", "2.0",
     _service_limit("vector-store", "cpu-limit")),
    ("vector-store-memory-limit", "256M", "1G",
     _service_limit("vector-store", "memory-limit")),

    # --- core log level ---
    ("log-level", "INFO", "DEBUG",
     lambda compose, launches: compose["services"]["ingest"]["command"][
         compose["services"]["ingest"]["command"].index("--log-level") + 1
     ]),
]


@pytest.mark.parametrize("key,default,override,extract", CASES,
                         ids=[c[0] for c in CASES])
def test_default_value(key, default, override, extract, build):
    """Without an override, the parameter takes its declared default."""
    compose, launches = build(minimal_config([]))
    assert extract(compose, launches) == default


@pytest.mark.parametrize("key,default,override,extract", CASES,
                         ids=[c[0] for c in CASES])
def test_override_applies(key, default, override, extract, build):
    """With an override entry, the new value replaces the default."""
    compose, launches = build(minimal_config([], overrides={key: override}))
    assert extract(compose, launches) == override
