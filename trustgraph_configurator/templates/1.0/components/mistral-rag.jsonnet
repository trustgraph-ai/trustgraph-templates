local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";

{

    with:: function(key, value)
        self + {
            ["mistral-rag-" + key]:: value,
        },

    "mistral-rag-max-output-tokens":: 4096,
    "mistral-rag-temperature":: 0.0,
    "mistral-rag-model":: "ministral-8b-latest",

    "text-completion-rag" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("mistral-credentials")
                .with_env_var("MISTRAL_TOKEN", "mistral-token");

            local containerRag =
                engine.container("text-completion-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-mistral",
                        "-p",
                        url.pulsar,
                        "--id",
                        "text-completion-rag",
                        "-x",
                        std.toString($["mistral-rag-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["mistral-rag-temperature"],
                        "-m",
                        $["mistral-rag-model"],
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSetRag = engine.containers(
                "text-completion-rag", [ containerRag ]
            );

            local serviceRag =
                engine.internalService(containerSetRag)
                .with_port(8080, 8080, "metrics");

            engine.resources([
                envSecrets,
                containerSetRag,
                serviceRag,
            ])

    },

} + prompts

