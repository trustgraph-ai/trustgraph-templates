"""
Per-component contract tests. One test (or class) per component asserting
the feature it's supposed to produce: correct processor classes, ids, and
baked-in default param values in the generated launch.yaml.
"""

import pytest

from helpers import minimal_config, find_processor


pytestmark = pytest.mark.features


# ---------------------------------------------------------------------------
# Core: ingest
# ---------------------------------------------------------------------------

class TestIngest:

    def test_ingest_group_has_expected_processors(self, build):
        _, launches = build(minimal_config([]))
        ingest = launches["ingest"]
        classes = [p["class"] for p in ingest["processors"]]
        assert "trustgraph.chunking.recursive.Processor" in classes
        assert "trustgraph.extract.kg.definitions.Processor" in classes
        assert "trustgraph.extract.kg.ontology.Processor" in classes
        assert "trustgraph.extract.kg.relationships.Processor" in classes
        assert "trustgraph.extract.kg.rows.Processor" in classes
        assert "trustgraph.prompt.template.Processor" in classes

    def test_ingest_defaults(self, build):
        _, launches = build(minimal_config([]))
        ingest = launches["ingest"]
        chunker = find_processor(ingest, "chunker")
        assert chunker["params"]["chunk_size"] == 2000
        assert chunker["params"]["chunk_overlap"] == 100
        prompt = find_processor(ingest, "prompt")
        assert prompt["params"]["concurrency"] == 1
        for pid in ("kg-extract-definitions", "kg-extract-ontology",
                    "kg-extract-relationships", "kg-extract-rows"):
            assert find_processor(ingest, pid)["params"]["concurrency"] == 1


# ---------------------------------------------------------------------------
# Core: rag
# ---------------------------------------------------------------------------

class TestRag:

    def test_rag_group_has_expected_processors(self, build):
        _, launches = build(minimal_config([]))
        rag = launches["rag"]
        classes = {p["class"] for p in rag["processors"]}
        expected = {
            "trustgraph.agent.orchestrator.Processor",
            "trustgraph.retrieval.graph_rag.Processor",
            "trustgraph.retrieval.document_rag.Processor",
            "trustgraph.retrieval.nlp_query.Processor",
            "trustgraph.retrieval.structured_query.Processor",
            "trustgraph.retrieval.structured_diag.Processor",
            "trustgraph.query.sparql.Processor",
            "trustgraph.prompt.template.Processor",
            "trustgraph.agent.mcp_tool.Service",
        }
        assert expected <= classes

    def test_graph_rag_defaults(self, build):
        _, launches = build(minimal_config([]))
        graph_rag = find_processor(launches["rag"], "graph-rag")
        params = graph_rag["params"]
        assert params["concurrency"] == 1
        assert params["entity_limit"] == 50
        assert params["triple_limit"] == 30
        assert params["edge_limit"] == 30
        assert params["edge_score_limit"] == 10
        assert params["max_subgraph_size"] == 100
        assert params["max_path_length"] == 2

    def test_document_rag_default_doc_limit(self, build):
        _, launches = build(minimal_config([]))
        doc_rag = find_processor(launches["rag"], "document-rag")
        assert doc_rag["params"]["doc_limit"] == 20

    def test_prompt_rag_default_concurrency(self, build):
        _, launches = build(minimal_config([]))
        prompt_rag = find_processor(launches["rag"], "prompt-rag")
        assert prompt_rag["params"]["concurrency"] == 1


# ---------------------------------------------------------------------------
# Stores
# ---------------------------------------------------------------------------

class TestRowStoreCassandra:

    def test_rows_group(self, build):
        _, launches = build(minimal_config([]))
        rows = launches["rows"]
        classes = {p["class"] for p in rows["processors"]}
        assert "trustgraph.query.rows.cassandra.Processor" in classes
        assert "trustgraph.storage.rows.cassandra.Processor" in classes

    def test_rows_cassandra_host(self, build):
        _, launches = build(minimal_config([]))
        for p in launches["rows"]["processors"]:
            assert p["params"]["cassandra_host"] == "cassandra"


class TestTripleStoreCassandra:

    def test_triples_group(self, build):
        _, launches = build(minimal_config([]))
        triples = launches["triples"]
        classes = {p["class"] for p in triples["processors"]}
        assert "trustgraph.query.triples.cassandra.Processor" in classes
        assert "trustgraph.storage.triples.cassandra.Processor" in classes

    def test_triples_cassandra_host(self, build):
        _, launches = build(minimal_config([]))
        for p in launches["triples"]["processors"]:
            assert p["params"]["cassandra_host"] == "cassandra"


class TestVectorStoreQdrant:

    def test_vector_store_group(self, build):
        _, launches = build(minimal_config([]))
        vs = launches["vector-store"]
        classes = {p["class"] for p in vs["processors"]}
        expected = {
            "trustgraph.query.doc_embeddings.qdrant.Processor",
            "trustgraph.storage.doc_embeddings.qdrant.Processor",
            "trustgraph.query.graph_embeddings.qdrant.Processor",
            "trustgraph.storage.graph_embeddings.qdrant.Processor",
            "trustgraph.query.row_embeddings.qdrant.Processor",
            "trustgraph.storage.row_embeddings.qdrant.Processor",
        }
        assert expected <= classes

    def test_vector_store_uri(self, build):
        _, launches = build(minimal_config([]))
        for p in launches["vector-store"]["processors"]:
            assert "store_uri" in p["params"]


# ---------------------------------------------------------------------------
# Embeddings
# ---------------------------------------------------------------------------

class TestEmbeddingsFastembed:

    def test_embeddings_group(self, build):
        _, launches = build(minimal_config([]))
        emb = launches["embeddings"]
        classes = {p["class"] for p in emb["processors"]}
        expected = {
            "trustgraph.embeddings.fastembed.Processor",
            "trustgraph.embeddings.document_embeddings.Processor",
            "trustgraph.embeddings.graph_embeddings.Processor",
            "trustgraph.embeddings.row_embeddings.Processor",
        }
        assert expected <= classes

    def test_embeddings_concurrency_default(self, build):
        _, launches = build(minimal_config([]))
        fe = find_processor(launches["embeddings"], "embeddings")
        assert fe["params"]["concurrency"] == 1


# ---------------------------------------------------------------------------
# LLMs — one parametrised test per component
# ---------------------------------------------------------------------------

# (component-name, class-suffix used in trustgraph.model.text_completion.<x>,
#  extra-params-to-check)
# tgi is xfailed: tgi.jsonnet never declared a models table, so selecting
# it as the only LLM leaves $["llm-models"] empty and the runtime-config
# generator crashes looking up a default flow. Pre-existing latent bug,
# surfaced by these tests.
_tgi_mark = pytest.mark.xfail(reason="tgi.jsonnet missing models table", strict=True)

LLM_CASES = [
    ("openai",          "openai",          {"max_output_tokens", "temperature"}, None),
    ("azure",           "azure",           {"max_output_tokens", "temperature"}, None),
    ("azure-openai",    "azure_openai",    {"max_output_tokens", "temperature"}, None),
    ("bedrock",         "bedrock",         {"max_output_tokens", "temperature"}, None),
    ("claude",          "claude",          {"max_output_tokens", "temperature"}, None),
    ("cohere",          "cohere",          {"temperature"},                       None),
    ("googleaistudio",  "googleaistudio",  {"max_output_tokens", "temperature"}, None),
    ("llamafile",       "llamafile",       set(),                                 None),
    ("lmstudio",        "lmstudio",        {"max_output_tokens", "temperature"}, None),
    ("mistral",         "mistral",         {"max_output_tokens", "temperature"}, None),
    ("ollama",          "ollama",          set(),                                 None),
    ("tgi",             "tgi",             {"max_output_tokens", "temperature"}, _tgi_mark),
    ("vertexai",        "vertexai",        {"max_output_tokens", "temperature",
                                            "private_key", "region"},             None),
    ("vllm",            "vllm",            {"max_output_tokens", "temperature"}, None),
]

_llm_params = [
    pytest.param(name, cls_suffix, keys, marks=[mark] if mark else [])
    for name, cls_suffix, keys, mark in LLM_CASES
]
_llm_names = [
    pytest.param(name, marks=[mark] if mark else [])
    for name, _cls, _keys, mark in LLM_CASES
]


@pytest.mark.parametrize("name,cls_suffix,expected_param_keys", _llm_params)
def test_llm_text_completion_group(name, cls_suffix, expected_param_keys, build):
    config = minimal_config([name], without=["openai"])
    _, launches = build(config)

    tc = launches["text-completion"]
    expected_class = f"trustgraph.model.text_completion.{cls_suffix}.Processor"

    ids = set()
    for p in tc["processors"]:
        ids.add(p["params"]["id"])
        assert p["class"] == expected_class, (
            f"{name}: expected class {expected_class}, got {p['class']}"
        )
        for key in expected_param_keys:
            assert key in p["params"], (
                f"{name}: processor {p['params']['id']} missing param {key}"
            )

    assert ids == {"text-completion", "text-completion-rag"}


@pytest.mark.parametrize("name", _llm_names)
def test_llm_concurrency_defaults(name, build):
    config = minimal_config([name], without=["openai"])
    _, launches = build(config)
    tc = launches["text-completion"]
    assert find_processor(tc, "text-completion")["params"]["concurrency"] == 1
    assert find_processor(tc, "text-completion-rag")["params"]["concurrency"] == 1
