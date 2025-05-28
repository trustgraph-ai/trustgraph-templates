local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    "prompt" +: {
    
        create:: function(engine)

            local container(x) =
                engine.container("prompt-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "prompt-template",
                        "-p",
                        url.pulsar,
                    ]
                    )
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "prompt-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8080, 8080, "metrics");

            engine.resources([
                containerSet(x)
                for x in std.range(0, $["prompt-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["prompt-replicas"] - 1)
            ])

    },

    "prompt-rag" +: {
    
        create:: function(engine)

            local container(x) =
                engine.container("prompt-rag-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "prompt-template",
                        "-p",
                        url.pulsar,
                        "--id",
                        "prompt-rag",
                    ]
                    )
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "prompt-rag-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8080, 8080, "metrics");

            engine.resources([
                containerSet(x)
                for x in std.range(0, $["prompt-rag-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["prompt-rag-replicas"] - 1)
            ])

    },

}

