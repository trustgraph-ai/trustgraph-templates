local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local garage = import "backends/garage.jsonnet";
local cassandra = import "backends/cassandra.jsonnet";

{

    "librarian" +: {
    
        create:: function(engine)

            local container =
                engine.container("librarian")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "librarian",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                        "--object-store-endpoint",
                        url.object_store,
                        "--object-store-access-key",
                        $["garage-access-key"],
                        "--object-store-secret-key",
                        $["garage-secret-key"],
                        "--object-store-region",
                        $["garage-region"],
                    ])
                    .with_limits("0.5", "256M")
                    .with_reservations("0.1", "256M");

            local containerSet = engine.containers(
                "librarian", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

// Garage and Cassandra are used by the Librarian
} + garage + cassandra

