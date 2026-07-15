"""
Per-component contract tests. One test (or class) per component asserting
the feature it's supposed to produce: correct processor classes, ids, and
baked-in default param values in the generated launch.yaml.
"""

import json

import pytest

from helpers import (
    minimal_config, find_processor, run_packager, extract_launches, _entry,
)


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


# ---------------------------------------------------------------------------
# Keyword index (FTS5) — sparse retrieval for Document-RAG (2.7 template)
# ---------------------------------------------------------------------------

# 2.7 baseline differs from the 2.3 BASELINE above: the control group needs
# the cassandra backend and garage object store to compile.
BASELINE_27 = [
    "rabbitmq", "trustgraph-base", "openai", "embeddings-fastembed",
    "cassandra", "triple-store-cassandra", "vector-store-qdrant",
    "garage",
]


def _build_27(components):
    config = [_entry(name) for name in BASELINE_27 + components]
    compose, additionals = run_packager(
        config, template="2.7", version="2.7.0",
    )
    return compose, extract_launches(additionals), additionals


class TestKeywordIndex:

    def test_component_deploys_kw_index_processor(self):
        _, launches, _ = _build_27(["keyword-index-fts5"])
        proc = find_processor(launches["keyword-index"], "kw-index")
        assert proc["class"] == "trustgraph.storage.kw_index.fts5.Processor"
        assert proc["params"]["index_path"] == "/data/kw-index.db"

    def test_component_mounts_data_volume(self):
        compose, _, _ = _build_27(["keyword-index-fts5"])
        volumes = compose["services"]["keyword-index"]["volumes"]
        assert any(v.startswith("keyword-index:/data") for v in volumes)

    def test_component_flips_document_rag_to_hybrid(self):
        _, launches, _ = _build_27(["keyword-index-fts5"])
        doc_rag = find_processor(launches["rag"], "document-rag")
        assert doc_rag["params"]["retrieval_mode"] == "hybrid"

    def test_without_component_document_rag_stays_vector(self):
        compose, launches, _ = _build_27([])
        doc_rag = find_processor(launches["rag"], "document-rag")
        assert doc_rag["params"]["retrieval_mode"] == "vector"
        assert "keyword-index" not in compose["services"]

    def test_blueprint_wires_keyword_index_topics(self):
        _, _, additionals = _build_27(["keyword-index-fts5"])
        cfg = json.loads(next(
            a["content"] for a in additionals
            if a["path"] == "trustgraph/config.json"
        ))
        bp = cfg["flow-blueprint"]["everything"]
        if isinstance(bp, str):
            bp = json.loads(bp)
        topics = bp["flow"]["document-rag:{id}"]["topics"]
        assert topics["keyword-index-request"] == \
            "request:tg:keyword-index:{workspace}:{id}"
        assert topics["keyword-index-response"] == \
            "response:tg:keyword-index:{workspace}:{id}"
        kw = bp["flow"]["kw-index:{id}"]["topics"]
        assert kw["input"] == "flow:tg:chunk-load:{workspace}:{id}"
        assert kw["request"] == "request:tg:keyword-index:{workspace}:{id}"


# ---------------------------------------------------------------------------
# Image-to-text (OpenAI-compatible vision) — optional service (2.7 template)
# ---------------------------------------------------------------------------

class TestImageToText:

    def test_component_deploys_image_to_text_processor(self):
        _, launches, _ = _build_27(["image-to-text-openai"])
        proc = find_processor(launches["image-to-text"], "image-to-text")
        assert proc["class"] == \
            "trustgraph.model.image_to_text.openai.Processor"
        assert proc["params"]["model"] == "gpt-5-mini"
        assert proc["params"]["max_output"] == 4096
        assert proc["params"]["concurrency"] == 1

    def test_component_gets_openai_credentials(self):
        compose, _, _ = _build_27(["image-to-text-openai"])
        env = compose["services"]["image-to-text"]["environment"]
        assert "OPENAI_TOKEN" in env
        assert "OPENAI_BASE_URL" in env

    def test_without_component_nothing_deploys(self):
        compose, launches, _ = _build_27([])
        assert "image-to-text" not in compose["services"]
        assert "image-to-text" not in launches

    def test_blueprint_wires_image_to_text(self):
        _, _, additionals = _build_27(["image-to-text-openai"])
        cfg = json.loads(next(
            a["content"] for a in additionals
            if a["path"] == "trustgraph/config.json"
        ))
        bp = cfg["flow-blueprint"]["everything"]
        if isinstance(bp, str):
            bp = json.loads(bp)
        topics = bp["flow"]["image-to-text:{id}"]["topics"]
        assert topics["request"] == \
            "request:tg:image-to-text:{workspace}:{id}"
        assert topics["response"] == \
            "response:tg:image-to-text:{workspace}:{id}"
        assert bp["interfaces"]["image-to-text"] == {
            "request": "request:tg:image-to-text:{workspace}:{id}",
            "response": "response:tg:image-to-text:{workspace}:{id}",
        }


# ---------------------------------------------------------------------------
# Chunker type override (2.7 template)
# ---------------------------------------------------------------------------

class TestChunkerType:

    def test_default_chunker_is_recursive(self):
        _, launches, _ = _build_27([])
        proc = find_processor(launches["ingest"], "chunker")
        assert proc["class"] == "trustgraph.chunking.recursive.Processor"

    def test_chunker_token_overrides_class(self):
        _, launches, _ = _build_27(["chunker-token"])
        proc = find_processor(launches["ingest"], "chunker")
        assert proc["class"] == "trustgraph.chunking.token.Processor"
