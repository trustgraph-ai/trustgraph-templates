local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    "graph-rag-entity-limit":: 50,
    "graph-rag-triple-limit":: 30,
    "graph-rag-max-subgraph-size":: 400,
    "graph-rag-max-path-length":: 2,

    "kg-extract-definitions" +: {
    
        create:: function(engine)

            local container(x) =
                engine.container("kg-extract-definitions-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "kg-extract-definitions",
                        "-p",
                        url.pulsar,
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "kg-extract-definitions-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet(x)
                for x in std.range(0, $["kg-extraction-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["kg-extraction-replicas"] - 1)
            ])

    },

    "kg-extract-relationships" +: {
    
        create:: function(engine)

            local container(x) =
                engine.container("kg-extract-relationships-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "kg-extract-relationships",
                        "-p",
                        url.pulsar,
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "kg-extract-relationships-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet(x)
                for x in std.range(0, $["kg-extraction-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["kg-extraction-replicas"] - 1)
            ])

    },

    "graph-rag" +: {
    
        create:: function(engine)

            local container(x) =
                engine.container("graph-rag-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "graph-rag",
                        "-p",
                        url.pulsar,
                        "--entity-limit",
                        std.toString($["graph-rag-entity-limit"]),
                        "--triple-limit",
                        std.toString($["graph-rag-triple-limit"]),
                        "--max-subgraph-size",
                        std.toString($["graph-rag-max-subgraph-size"]),
                        "--max-path-length",
                        std.toString($["graph-rag-max-path-length"]),
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "graph-rag-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet(x)
                for x in std.range(0, $["graph-rag-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["graph-rag-replicas"] - 1)
            ])

    },

    "graph-embeddings" +: {
    
        create:: function(engine)

            local container =
                engine.container("graph-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "graph-embeddings",
                        "-p",
                        url.pulsar,
                    ])
                    .with_limits("1.0", "512M")
                    .with_reservations("0.5", "512M");

            local containerSet = engine.containers(
                "graph-embeddings", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}

