local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    "graph-rag" +: {

        concurrency:: 1,
        "entity-limit":: 50,
        "triple-limit":: 30,
        "edge-limit":: 30,
        "edge-score-limit":: 10,
        "max-subgraph-size":: 100,
        "max-path-length":: 2,
        "cpu-limit":: "0.5",
        "cpu-reservation":: "0.1",
        "memory-limit":: "128M",
        "memory-reservation":: "128M",

        local logLevel = $.parameters["log-level"],

        create:: function(engine)

            local concurrency = self.concurrency;
            local entityLimit = self["entity-limit"];
            local tripleLimit = self["triple-limit"];
            local edgeLimit = self["edge-limit"];
            local edgeScoreLimit = self["edge-score-limit"];
            local maxSubgraphSize = self["max-subgraph-size"];
            local maxPathLength = self["max-path-length"];
            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];

            local container =
                engine.container("graph-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "graph-rag",
                    ] + $["pub-sub-args"] + [
                        "--concurrency",
                        std.toString(concurrency),
                        "--entity-limit",
                        std.toString(entityLimit),
                        "--triple-limit",
                        std.toString(tripleLimit),
                        "--edge-limit",
                        std.toString(edgeLimit),
                        "--edge-score-limit",
                        std.toString(edgeScoreLimit),
                        "--max-subgraph-size",
                        std.toString(maxSubgraphSize),
                        "--max-path-length",
                        std.toString(maxPathLength),
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(self["cpu-reservation"], memoryReservation);

            local containerSet = engine.containers(
                "graph-rag", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "graph-embeddings" +: {

        "cpu-limit":: "1.0",
        "cpu-reservation":: "0.5",
        "memory-limit":: "256M",
        "memory-reservation":: "256M",

        create:: function(engine)

            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];

            local container =
                engine.container("graph-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "graph-embeddings",
                    ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(self["cpu-reservation"], memoryReservation);

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

    "sparql-query" +: {

        "cpu-limit":: "1.0",
        "cpu-reservation":: "0.5",
        "memory-limit":: "256M",
        "memory-reservation":: "256M",

        create:: function(engine)

            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];

            local container =
                engine.container("sparql-query")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "sparql-query",
                    ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(self["cpu-reservation"], memoryReservation);

            local containerSet = engine.containers(
                "sparql-query", [ container ]
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

