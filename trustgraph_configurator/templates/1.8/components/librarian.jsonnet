local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local ceph = import "stores/ceph.jsonnet";
local cassandra = import "stores/cassandra.jsonnet";

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

// Ceph and Cassandra are used by the Librarian
} + ceph + cassandra

