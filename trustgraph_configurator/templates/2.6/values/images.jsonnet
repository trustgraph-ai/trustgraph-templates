// Container image references used across the templates.
// TrustGraph images are tagged with the version from
// version.jsonnet (injected by the packager); third-party
// images are pinned explicitly here.

local version = import "version.jsonnet";
{
    cassandra: "docker.io/cassandra:5.0.8",
    neo4j: "docker.io/neo4j:2026.04.0-community-bullseye",
    pulsar: "docker.io/apachepulsar/pulsar:4.2.1",
    rabbitmq: "docker.io/rabbitmq:4.1-management",
    kafka: "docker.io/apache/kafka:4.1.2",
    pulsar_manager: "docker.io/apachepulsar/pulsar-manager:v0.4.0",
    etcd: "quay.io/coreos/etcd:v3.6.11",
    minio: "docker.io/minio/minio:v0.20260512.133534-dev",
    garage: "docker.io/dxflrs/garage:v2.3.0",
    milvus: "docker.io/milvusdb/milvus:v2.6.17",
    prometheus: "docker.io/prom/prometheus:v3.11.3",
    grafana: "docker.io/grafana/grafana:13.0.1",
    loki: "docker.io/grafana/loki:3.7.2",
    trustgraph_base: "docker.io/trustgraph/trustgraph-base:" + version,
    trustgraph_flow: "docker.io/trustgraph/trustgraph-flow:" + version,
    trustgraph_ocr: "docker.io/trustgraph/trustgraph-ocr:" + version,
    trustgraph_bedrock: "docker.io/trustgraph/trustgraph-bedrock:" + version,
    trustgraph_vertexai: "docker.io/trustgraph/trustgraph-vertexai:" + version,
    trustgraph_hf: "docker.io/trustgraph/trustgraph-hf:" + version,
    trustgraph_mcp: "docker.io/trustgraph/trustgraph-mcp:" + version,
    trustgraph_unstructured: "docker.io/trustgraph/trustgraph-unstructured:" + version,
    trustgraph_enterprise: "docker.io/trustgraph/trustgraph-enterprise:0.9.6",
    qdrant: "docker.io/qdrant/qdrant:v1.18.0",
    memgraph_mage: "docker.io/memgraph/memgraph-mage:3.10.1",
    memgraph_lab: "docker.io/memgraph/lab:3.10.0",
    falkordb: "docker.io/falkordb/falkordb:v4.18.7",
    "workbench-ui": "docker.io/trustgraph/workbench-ui:1.8.2",
    ui: "docker.io/trustgraph/trustgraph-ui:0.3.3",
    "ddg-mcp-server": "docker.io/trustgraph/ddg-mcp-server:0.1.0",
    "tgi-service-intel-xpu": "ghcr.io/huggingface/text-generation-inference:3.3.1-intel-xpu",
    "tgi-service-cpu": "ghcr.io/huggingface/text-generation-inference:3.3.7-intel-cpu",
    "tgi-service-gaudi": "ghcr.io/huggingface/text-generation-inference:sha-b4adbf2-gaudi",
    "vllm-service-intel-xpu": "docker.io/intel/vllm:0.17.0-xpu",
    "vllm-service-gaudi": "docker.io/trustgraph/vllm-hpu:027f5645",
    "vllm-service-nvidia": "docker.io/vllm/vllm-openai:latest",
    "vllm-service-intel-battlemage": "docker.io/intelanalytics/ipex-llm-serving-xpu:0.2.0-b6",
}
