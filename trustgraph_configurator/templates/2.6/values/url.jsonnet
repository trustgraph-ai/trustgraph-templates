// Internal service URLs used by processors to reach infrastructure
// components (pulsar, object store, vector stores). Hostnames assume
// the deployment-internal DNS names produced by the renderers.

{
    pulsar: "pulsar://pulsar:6650",
    pulsar_admin: "http://pulsar:8080",
    amqp: "amqp://guest:guest@rabbitmq:5672",
    milvus: "http://milvus:19530",
    qdrant: "http://qdrant:6333",
    object_store: "garage:3900",
}
