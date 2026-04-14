local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";
local models = import "parameters/vertexai.jsonnet";

{

    with:: function(key, value)
        self + {
            ["vertexai-" + key]:: value,
        },

    "vertexai-private-key":: "/vertexai/private.json",
    "vertexai-region":: "us-central1",
    "vertexai-max-output-tokens":: 4096,
    "vertexai-temperature":: 0.0,
    "vertexai-models":: models,

    "llm-models" +:: $["vertexai-models"],

    parameters +:: {
        "text-completion-cpu-limit": "0.5",
        "text-completion-cpu-reservation": "0.1",
        "text-completion-memory-limit": "256M",
        "text-completion-memory-reservation": "256M",
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
                                class: "trustgraph.model.text_completion.vertexai.Processor",
                                params: {
                                    id: "text-completion",
                                    concurrency: textCompletionConc,
                                    private_key: $["vertexai-private-key"],
                                    region: $["vertexai-region"],
                                    max_output_tokens: $["vertexai-max-output-tokens"],
                                    temperature: $["vertexai-temperature"],
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.model.text_completion.vertexai.Processor",
                                params: {
                                    id: "text-completion-rag",
                                    concurrency: textCompletionRagConc,
                                    private_key: $["vertexai-private-key"],
                                    region: $["vertexai-region"],
                                    max_output_tokens: $["vertexai-max-output-tokens"],
                                    temperature: $["vertexai-temperature"],
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local credsVol = engine.secretVolume(
	        "vertexai-creds",
	        "./vertexai",
		{
		    "private.json": importstr "vertexai/private.json",
		}
            );

            local container =
                engine.container("text-completion")
                    .with_image(images.trustgraph_vertexai)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_volume_mount(credsVol, "/vertexai")
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
                cfgVol,
                credsVol,
                containerSet,
                service,
            ])

    },

} + prompts
