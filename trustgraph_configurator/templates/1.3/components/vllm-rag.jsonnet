local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";

{

    with:: function(key, value)
        self + {
            ["vllm-rag-" + key]:: value,
        },

    "vllm-rag-max-output-tokens":: 1024,
    "vllm-rag-temperature":: 0.0,
    "vllm-rag-model":: "TheBloke/Mistral-7B-v0.1-AWQ",

    "text-completion-rag" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("vllm-credentials")
                .with_env_var("VLLM_BASE_URL", "vllm-url");

            local containerRag =
                engine.container("text-completion-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-vllm",
                        "-p",
                        url.pulsar,
                        "--id",
                        "text-completion-rag",
                        "--concurrency",
                        std.toString($["text-completion-rag-concurrency"]),
                        "--model",
                        std.toString($["vllm-model"]),
                        "-x",
                        std.toString($["vllm-rag-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["vllm-rag-temperature"],
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSetRag = engine.containers(
                "text-completion-rag", [ containerRag ]
            );

            local serviceRag =
                engine.internalService(containerSetRag)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSetRag,
                serviceRag,
            ])

    },

} + prompts

