local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    "kg-extract-objects" +: {
    
        create:: function(engine)

            local container =
                engine.container("kg-extract-objects")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "kg-extract-objects",
                        "-p",
                        url.pulsar,
                        "--concurrency",
                        std.toString($["kg-extraction-concurrency"]),
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "kg-extract-objects", [ container ]
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

