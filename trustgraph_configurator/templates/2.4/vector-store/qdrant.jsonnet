local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local qdrant = import "backends/qdrant.jsonnet";

qdrant + {

    parameters +:: {
        "vector-store-cpu-limit": "0.5",
        "vector-store-cpu-reservation": "0.1",
        "vector-store-memory-limit": "256M",
        "vector-store-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "vector-store" +: {

        local pars = $.parameters,

        local cpuLimit = pars["vector-store-cpu-limit"],
        local cpuReservation = pars["vector-store-cpu-reservation"],
        local memoryLimit = pars["vector-store-memory-limit"],
        local memoryReservation = pars["vector-store-memory-reservation"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "vector-store-cfg", "launch/vector-store",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.query.doc_embeddings.qdrant.Processor",
                                params: {
                                    id: "doc-embeddings-query",
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.doc_embeddings.qdrant.Processor",
                                params: {
                                    id: "doc-embeddings-write",
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.query.graph_embeddings.qdrant.Processor",
                                params: {
                                    id: "graph-embeddings-query",
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.graph_embeddings.qdrant.Processor",
                                params: {
                                    id: "graph-embeddings-write",
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.query.row_embeddings.qdrant.Processor",
                                params: {
                                    id: "row-embeddings-query",
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.row_embeddings.qdrant.Processor",
                                params: {
                                    id: "row-embeddings-write",
                                    store_uri: url.qdrant,
                                } + $["pub-sub-params"],
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
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

// Qdrant is used by these adapters
} + qdrant
