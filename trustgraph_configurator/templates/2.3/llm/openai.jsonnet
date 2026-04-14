local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";
local models = import "parameters/openai.jsonnet";

{

    with:: function(key, value)
        self + {
            ["openai-" + key]:: value,
        },

    "openai-max-output-tokens":: 4096,
    "openai-temperature":: 0.0,
    "openai-models":: models,

    "llm-models" +:: $["openai-models"],

    parameters +:: {
        "text-completion-cpu-limit": "0.5",
        "text-completion-cpu-reservation": "0.1",
        "text-completion-memory-limit": "128M",
        "text-completion-memory-reservation": "128M",
        "text-completion-concurrency": 1,
        "text-completion-rag-concurrency": 1,
    },

    local logLevel = $.parameters["log-level"],

    "text-completion" +: {

        local pars = $.parameters,
        local cpuLimit = pars["text-completion-cpu-limit"],
        local cpuReservation = pars["text-completion-cpu-reservation"],
        local memoryLimit = pars["text-completion-memory-limit"],
        local memoryReservation = pars["text-completion-memory-reservation"],
        local textCompletionConc = pars["text-completion-concurrency"],
        local textCompletionRagConc = pars["text-completion-rag-concurrency"],


        create:: function(engine)

            local cfgVol = engine.configVolume(
                "text-completion-launch-cfg", "launch/text-completion",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.model.text_completion.openai.Processor",
                                params: {
                                    id: "text-completion",
                                    concurrency: textCompletionConc,
                                    max_output_tokens: $["openai-max-output-tokens"],
                                    temperature: $["openai-temperature"],
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.model.text_completion.openai.Processor",
                                params: {
                                    id: "text-completion-rag",
                                    concurrency: textCompletionRagConc,
                                    max_output_tokens: $["openai-max-output-tokens"],
                                    temperature: $["openai-temperature"],
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local envSecrets = engine.envSecrets("openai-credentials")
                .with_env_var("OPENAI_TOKEN", "openai-token")
                .with_env_var("OPENAI_BASE_URL", "openai-url");

            local container =
                engine.container("text-completion")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_env_var_secrets(envSecrets)
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(
                        cpuReservation,
                        memoryReservation
                    );

            local containerSet = engine.containers(
                "text-completion", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                cfgVol,
                containerSet,
                service,
            ])

    },

} + prompts
