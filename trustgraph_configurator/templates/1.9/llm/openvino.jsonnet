local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/slm.jsonnet";
local models = import "parameters/openvino.jsonnet";

{

    with:: function(key, value)
        self + {
            ["openvino-" + key]:: value,
        },

    "openvino-max-output-tokens":: 4096,
    "openvino-temperature":: 0.0,
    "openvino-models":: models,

    "llm-models" +:: $["openvino-models"],

    "text-completion" +: {

        create:: function(engine)

            local concurrency = self.concurrency;

            // OpenVINO uses /v3 API instead of /v1
            local envSecrets = engine.envSecrets("openvino-credentials")
                .with_env_var("OPENAI_TOKEN", "openvino-token")
                .with_env_var("OPENAI_BASE_URL", "openvino-url");

            local container =
                engine.container("text-completion")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-openai",
                        "-p",
                        url.pulsar,
                        "--concurrency",
                        std.toString(concurrency),
                        "-x",
                        std.toString($["openvino-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["openvino-temperature"],
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

    "text-completion-rag" +: {

        create:: function(engine)

            local concurrency = self.concurrency;

            local envSecrets = engine.envSecrets("openvino-credentials")
                .with_env_var("OPENAI_TOKEN", "openvino-token")
                .with_env_var("OPENAI_BASE_URL", "openvino-url");

            local containerRag =
                engine.container("text-completion-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-openai",
                        "-p",
                        url.pulsar,
                        "--id",
                        "text-completion-rag",
                        "--concurrency",
                        std.toString(concurrency),
                        "-x",
                        std.toString($["openvino-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["openvino-temperature"],
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
