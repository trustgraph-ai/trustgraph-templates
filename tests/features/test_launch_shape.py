"""
Structural invariants for every launch.yaml generated across a handful of
representative configs. Cheap, broad coverage that catches "I generated a
malformed YAML" or "two processors have the same id" regressions without
needing to know what's in any particular group.
"""

import pytest

from helpers import minimal_config


pytestmark = pytest.mark.features


CONFIGS = {
    "baseline": lambda: minimal_config([]),
    "claude-instead-of-openai": lambda: minimal_config(
        ["claude"], without=["openai"]
    ),
    "bedrock-instead-of-openai": lambda: minimal_config(
        ["bedrock"], without=["openai"]
    ),
    "vertexai-instead-of-openai": lambda: minimal_config(
        ["vertexai"], without=["openai"]
    ),
}


@pytest.fixture(params=sorted(CONFIGS.keys()))
def built(request, build):
    config = CONFIGS[request.param]()
    return request.param, build(config)


class TestLaunchShape:

    def test_processors_key_exists(self, built):
        _, (_, launches) = built
        assert launches, "no launch.yaml files generated"
        for group, doc in launches.items():
            assert isinstance(doc, dict), f"{group}: launch.yaml not a mapping"
            assert "processors" in doc, f"{group}: missing processors key"
            assert isinstance(doc["processors"], list), (
                f"{group}: processors is not a list"
            )

    def test_each_processor_has_class_and_params(self, built):
        _, (_, launches) = built
        for group, doc in launches.items():
            for p in doc["processors"]:
                assert "class" in p, f"{group}: processor missing class"
                assert "params" in p, f"{group}: processor missing params"
                assert isinstance(p["params"], dict), (
                    f"{group}: processor params not a mapping"
                )

    def test_class_names_use_trustgraph_namespace(self, built):
        _, (_, launches) = built
        for group, doc in launches.items():
            for p in doc["processors"]:
                cls = p["class"]
                assert cls.startswith("trustgraph."), (
                    f"{group}: processor class {cls!r} not in trustgraph.*"
                )

    def test_ids_unique_within_group(self, built):
        _, (_, launches) = built
        for group, doc in launches.items():
            ids = []
            for p in doc["processors"]:
                pid = p["params"].get("id")
                assert pid, f"{group}: processor missing params.id"
                ids.append(pid)
            assert len(ids) == len(set(ids)), (
                f"{group}: duplicate ids: {ids}"
            )

    def test_pubsub_backend_merged_into_every_params(self, built):
        """Every processor should carry pub-sub-params — otherwise the
        processor won't know how to talk to rabbitmq / pulsar."""
        _, (_, launches) = built
        for group, doc in launches.items():
            for p in doc["processors"]:
                params = p["params"]
                assert "pubsub_backend" in params, (
                    f"{group}/{params.get('id')}: missing pubsub_backend"
                )


# Expected class strings the builder should emit, keyed by
# (launch-group, processor-id). These are the contract this repo promises
# to the trustgraph-flow runtime — if the runtime renames one of its
# processor classes, update the string here in lockstep. The check is
# purely textual; no Python imports.
EXPECTED_CLASSES = {
    "baseline": {
        ("ingest", "chunker"):
            "trustgraph.chunking.recursive.Processor",
        ("ingest", "kg-extract-definitions"):
            "trustgraph.extract.kg.definitions.Processor",
        ("ingest", "kg-extract-ontology"):
            "trustgraph.extract.kg.ontology.Processor",
        ("ingest", "kg-extract-relationships"):
            "trustgraph.extract.kg.relationships.Processor",
        ("ingest", "kg-extract-rows"):
            "trustgraph.extract.kg.rows.Processor",
        ("ingest", "prompt"):
            "trustgraph.prompt.template.Processor",

        ("rag", "agent-manager"):
            "trustgraph.agent.orchestrator.Processor",
        ("rag", "graph-rag"):
            "trustgraph.retrieval.graph_rag.Processor",
        ("rag", "document-rag"):
            "trustgraph.retrieval.document_rag.Processor",
        ("rag", "nlp-query"):
            "trustgraph.retrieval.nlp_query.Processor",
        ("rag", "structured-query"):
            "trustgraph.retrieval.structured_query.Processor",
        ("rag", "structured-diag"):
            "trustgraph.retrieval.structured_diag.Processor",
        ("rag", "sparql-query"):
            "trustgraph.query.sparql.Processor",
        ("rag", "prompt-rag"):
            "trustgraph.prompt.template.Processor",
        ("rag", "mcp-tool"):
            "trustgraph.agent.mcp_tool.Service",

        ("text-completion", "text-completion"):
            "trustgraph.model.text_completion.openai.Processor",
        ("text-completion", "text-completion-rag"):
            "trustgraph.model.text_completion.openai.Processor",

        ("embeddings", "embeddings"):
            "trustgraph.embeddings.fastembed.Processor",
        ("embeddings", "document-embeddings"):
            "trustgraph.embeddings.document_embeddings.Processor",
        ("embeddings", "graph-embeddings"):
            "trustgraph.embeddings.graph_embeddings.Processor",
        ("embeddings", "row-embeddings"):
            "trustgraph.embeddings.row_embeddings.Processor",

        ("rows", "rows-query"):
            "trustgraph.query.rows.cassandra.Processor",
        ("rows", "rows-write"):
            "trustgraph.storage.rows.cassandra.Processor",

        ("triples", "triples-query"):
            "trustgraph.query.triples.cassandra.Processor",
        ("triples", "triples-write"):
            "trustgraph.storage.triples.cassandra.Processor",

        ("vector-store", "doc-embeddings-query"):
            "trustgraph.query.doc_embeddings.qdrant.Processor",
        ("vector-store", "doc-embeddings-write"):
            "trustgraph.storage.doc_embeddings.qdrant.Processor",
        ("vector-store", "graph-embeddings-query"):
            "trustgraph.query.graph_embeddings.qdrant.Processor",
        ("vector-store", "graph-embeddings-write"):
            "trustgraph.storage.graph_embeddings.qdrant.Processor",
        ("vector-store", "row-embeddings-query"):
            "trustgraph.query.row_embeddings.qdrant.Processor",
        ("vector-store", "row-embeddings-write"):
            "trustgraph.storage.row_embeddings.qdrant.Processor",
    },
}


class TestExpectedClassStrings:
    """For every (group, id) we care about, the builder must emit exactly
    the class string in EXPECTED_CLASSES. Textual check only — no Python
    import, no filesystem probe of the runtime package. Updates to the
    runtime must update this table in lockstep."""

    def test_expected_class_strings(self, built):
        config_name, (_, launches) = built
        if config_name not in EXPECTED_CLASSES:
            pytest.skip(f"no expected-class table for config {config_name}")

        expected = EXPECTED_CLASSES[config_name]
        mismatches = []
        for (group, pid), expected_class in expected.items():
            doc = launches.get(group)
            if doc is None:
                mismatches.append(f"{group}: group not emitted")
                continue
            found = [p for p in doc["processors"]
                     if p["params"].get("id") == pid]
            if not found:
                mismatches.append(f"{group}/{pid}: processor not emitted")
                continue
            actual = found[0]["class"]
            if actual != expected_class:
                mismatches.append(
                    f"{group}/{pid}: expected {expected_class!r}, "
                    f"got {actual!r}"
                )
        assert not mismatches, "\n".join(mismatches)
