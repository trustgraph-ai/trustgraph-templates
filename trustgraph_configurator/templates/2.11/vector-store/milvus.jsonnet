local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local cassandra_hosts = "cassandra";
local milvus = import "backends/milvus.jsonnet";

milvus + {

    parameters +:: {
        "store-graph-embeddings-replicas": 1,
        "query-graph-embeddings-replicas": 1,
        "store-doc-embeddings-replicas": 1,
        "query-doc-embeddings-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],
    local pars = $.parameters,

    "store-graph-embeddings" +: {
    
        create:: function(engine)

            local container =
                engine.container("store-graph-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "ge-write-milvus",
] + $["pub-sub-args"] + [
                        "-t",
                        url.milvus,
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "store-graph-embeddings", [ container ]
            ).with_replicas(pars["store-graph-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "query-graph-embeddings" +: {
    
        create:: function(engine)

            local container =
                engine.container("query-graph-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "ge-query-milvus",
] + $["pub-sub-args"] + [
                        "-t",
                        url.milvus,
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "query-graph-embeddings", [ container ]
            ).with_replicas(pars["query-graph-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "store-doc-embeddings" +: {
    
        create:: function(engine)

            local container =
                engine.container("store-doc-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "de-write-milvus",
] + $["pub-sub-args"] + [
                        "-t",
                        url.milvus,
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "store-doc-embeddings", [ container ]
            ).with_replicas(pars["store-doc-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "query-doc-embeddings" +: {
    
        create:: function(engine)

            local container =
                engine.container("query-doc-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "de-query-milvus",
] + $["pub-sub-args"] + [
                        "-t",
                        url.milvus,
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "query-doc-embeddings", [ container ]
            ).with_replicas(pars["query-doc-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])


    }

}

