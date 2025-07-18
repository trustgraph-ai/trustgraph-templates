local version = import "version.jsonnet";
{
    cassandra: "docker.io/cassandra:4.1.6",
    neo4j: "docker.io/neo4j:5.26.0-community-bullseye",
    pulsar: "docker.io/apachepulsar/pulsar:3.3.1",
    pulsar_manager: "docker.io/apachepulsar/pulsar-manager:v0.4.0",
    etcd: "quay.io/coreos/etcd:v3.5.15",
    minio: "docker.io/minio/minio:RELEASE.2025-02-03T21-03-04Z",
    milvus: "docker.io/milvusdb/milvus:v2.4.9",
    prometheus: "docker.io/prom/prometheus:v2.53.2",
    grafana: "docker.io/grafana/grafana:11.1.4",
    trustgraph_base: "docker.io/trustgraph/trustgraph-base:" + version,
    trustgraph_flow: "docker.io/trustgraph/trustgraph-flow:" + version,
    trustgraph_ocr: "docker.io/trustgraph/trustgraph-ocr:" + version,
    trustgraph_bedrock: "docker.io/trustgraph/trustgraph-bedrock:" + version,
    trustgraph_vertexai: "docker.io/trustgraph/trustgraph-vertexai:" + version,
    trustgraph_hf: "docker.io/trustgraph/trustgraph-hf:" + version,
    qdrant: "docker.io/qdrant/qdrant:v1.13.3",
    memgraph_mage: "docker.io/memgraph/memgraph-mage:1.22-memgraph-2.22",
    memgraph_lab: "docker.io/memgraph/lab:2.19.1",
    falkordb: "docker.io/falkordb/falkordb:latest",
    "workbench-ui": "docker.io/trustgraph/workbench-ui:0.3.10",
    "tgi-service-intel-xpu": "ghcr.io/huggingface/text-generation-inference:3.3.1-intel-xpu",
    "tgi-service-cpu": "ghcr.io/huggingface/text-generation-inference:3.3.1-intel-cpu",
    "tgi-service-gaudi": "ghcr.io/huggingface/text-generation-inference:sha-f140440-gaudi",
    "vllm-service-intel-xpu": "docker.io/intel/vllm:0.8.0-xpu",
    "vllm-service-gaudi": "docker.io/trustgraph/vllm-hpu:027f5645",
    "vllm-service-nvidia": "docker.io/vllm/vllm-openai:latest",
}
