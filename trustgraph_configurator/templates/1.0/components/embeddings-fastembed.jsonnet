local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";

{

    "embeddings-model":: "sentence-transformers/all-MiniLM-L6-v2",

    embeddings +: {
    
        create:: function(engine)

            local container(x) =
                engine.container("embeddings-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "embeddings-fastembed",
                        "-p",
                        url.pulsar,
                        "-m",
                        $["embeddings-model"],
                    ])
                    .with_limits("1.0", "400M")
                    .with_reservations("0.5", "400M");

            local containerSet(x) = engine.containers(
                "embeddings-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet(x)
                for x in std.range(0, $["embeddings-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["embeddings-replicas"] - 1)
            ])

    },

}

