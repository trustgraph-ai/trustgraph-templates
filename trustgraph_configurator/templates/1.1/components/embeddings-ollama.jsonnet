local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    "embeddings-model":: "mxbai-embed-large",
    "ollama-url":: "${OLLAMA_HOST}",

    embeddings +: {
    
        create:: function(engine)

            local container =
                engine.container("embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "embeddings-ollama",
                        "-p",
                        url.pulsar,
                        "--concurrency",
                        std.toString($["embeddings-concurrency"]),
                        "-m",
                        $["embeddings-model"],
                        "-r",
                        $["ollama-url"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "embeddings", [ container ]
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

