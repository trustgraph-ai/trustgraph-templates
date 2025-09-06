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
    "vllm-model":: "TheBloke/Mistral-7B-v0.1-AWQ",

    "text-completion" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("vllm-credentials")
                .with_env_var("VLLM_BASE_URL", "vllm-url");

            local container =
                engine.container("text-completion")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-vllm",
                        "-p",
                        url.pulsar,
                        "--concurrency",
                        std.toString($["text-completion-concurrency"]),
                        "--model",
                        std.toString($["vllm-model"]),
                        "-x",
                        std.toString($["vllm-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["vllm-temperature"],
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "text-completion", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

} + prompts

