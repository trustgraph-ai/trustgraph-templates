local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";

{

    with:: function(key, value)
        self + {
            ["vllm-" + key]:: value,
        },

    "vllm-max-output-tokens":: 1024,
    "vllm-temperature":: 0.0,

    "text-completion" +: {
    
        create:: function(engine)

            local container =
                engine.container("text-completion")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-openai",
                        "-p",
                        url.pulsar,
                        "--id",
                        "text-completion-rag",
                        "--url",
                        "http://vllm-service:8899/v1",
                        "--concurrency",
                        std.toString($["text-completion-concurrency"]),
                        "-x",
                        std.toString($["vllm-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["vllm-temperature"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "text-completion", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8080, 8080, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

} + prompts

