local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";
local models = import "llm-models/claude.jsonnet";

{

    with:: function(key, value)
        self + {
            ["claude-rag-" + key]:: value,
        },

    "claude-rag-model":: "claude-3-sonnet-20240229",
    "claude-rag-max-output-tokens":: 4096,
    "claude-rag-temperature":: 0.0,

    "llm-models" +:: models,

    "text-completion-rag" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("claude-credentials")
                .with_env_var("CLAUDE_KEY", "claude-key");

            local containerRag =
                engine.container("text-completion-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-claude",
                        "-p",
                        url.pulsar,
                        "--id",
                        "text-completion-rag",
                        "-x",
                        std.toString($["claude-rag-max-output-tokens"]),
                        "-m",
                        $["claude-rag-model"],
                        "-t",
                        "%0.3f" % $["claude-rag-temperature"],
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

