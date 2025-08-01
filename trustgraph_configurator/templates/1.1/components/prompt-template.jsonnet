local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    "prompt" +: {
    
        create:: function(engine)

            local container =
                engine.container("prompt")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "prompt-template",
                        "-p",
                        url.pulsar,
                        "--concurrency",
                        std.toString($["prompt-concurrency"]),
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "prompt", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8080, 8080, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "prompt-rag" +: {
    
        create:: function(engine)

            local container =
                engine.container("prompt-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "prompt-template",
                        "-p",
                        url.pulsar,
                        "--id",
                        "prompt-rag",
                        "--concurrency",
                        std.toString($["prompt-rag-concurrency"]),
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "prompt-rag", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8080, 8080, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}

