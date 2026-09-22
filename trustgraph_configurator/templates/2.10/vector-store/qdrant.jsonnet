local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local qdrant = import "backends/qdrant.jsonnet";

qdrant + {

    parameters +:: {
        "doc-embeddings-query-concurrency": 1,
        "doc-embeddings-write-concurrency": 1,
        "graph-embeddings-query-concurrency": 1,
        "graph-embeddings-write-concurrency": 1,
        "row-embeddings-query-concurrency": 1,
        "row-embeddings-write-concurrency": 1,
        "vector-store-cpu-limit": "0.5",
        "vector-store-cpu-reservation": "0.1",
        "vector-store-memory-limit": "256M",
        "vector-store-memory-reservation": "256M",
        "vector-store-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],

    "vector-store" +: {

        local pars = $.parameters,

        local docEmbQueryConc = pars["doc-embeddings-query-concurrency"],
        local docEmbWriteConc = pars["doc-embeddings-write-concurrency"],
        local graphEmbQueryConc = pars["graph-embeddings-query-concurrency"],
        local graphEmbWriteConc = pars["graph-embeddings-write-concurrency"],
        local rowEmbQueryConc = pars["row-embeddings-query-concurrency"],
        local rowEmbWriteConc = pars["row-embeddings-write-concurrency"],
        local cpuLimit = pars["vector-store-cpu-limit"],
        local cpuReservation = pars["vector-store-cpu-reservation"],
        local memoryLimit = pars["vector-store-memory-limit"],
        local memoryReservation = pars["vector-store-memory-reservation"],
        local replicas = pars["vector-store-replicas"],

        create:: function(engine)

            // Collection geometry applied only by the WRITE processors when
            // they create collections. 1/1 single-node by default;
            // qdrant-cluster raises both to the ring size. Query processors
            // don't create collections, so they don't take these.
            local collectionParams = {
                qdrant_replication_factor: $["qdrant-replication-factor"],
                qdrant_shard_number: $["qdrant-shard-number"],
            };

            local cfgVol = engine.configVolume(
                "vector-store-cfg", "launch/vector-store",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.query.doc_embeddings.qdrant.Processor",
                                params: {
                                    id: "doc-embeddings-query",
                                    concurrency: docEmbQueryConc,
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.doc_embeddings.qdrant.Processor",
                                params: {
                                    id: "doc-embeddings-write",
                                    concurrency: docEmbWriteConc,
                                    store_uri: url.qdrant,
                                } + collectionParams + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.query.graph_embeddings.qdrant.Processor",
                                params: {
                                    id: "graph-embeddings-query",
                                    concurrency: graphEmbQueryConc,
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.graph_embeddings.qdrant.Processor",
                                params: {
                                    id: "graph-embeddings-write",
                                    concurrency: graphEmbWriteConc,
                                    store_uri: url.qdrant,
                                } + collectionParams + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.query.row_embeddings.qdrant.Processor",
                                params: {
                                    id: "row-embeddings-query",
                                    concurrency: rowEmbQueryConc,
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.row_embeddings.qdrant.Processor",
                                params: {
                                    id: "row-embeddings-write",
                                    concurrency: rowEmbWriteConc,
                                    store_uri: url.qdrant,
                                } + collectionParams + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local container =
                engine.container("vector-store")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "vector-store", [ container ]
            ).with_replicas(replicas);

            local service =
                engine.internalService("vector-store", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

// Qdrant is used by these adapters
} + qdrant
