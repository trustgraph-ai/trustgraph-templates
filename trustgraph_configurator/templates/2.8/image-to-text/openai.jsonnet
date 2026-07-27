// Image-to-text (OpenAI-compatible vision) - describes images with a
// vision-capable chat-completions model. Deploys the image-to-text
// processor, which serves the optional image-to-text request/response
// interface (tg-describe-image, service/image-to-text). Uses the same
// openai-credentials secrets as the OpenAI LLM component (OPENAI_TOKEN,
// OPENAI_BASE_URL), so it can point at any OpenAI-compatible endpoint
// serving a vision model; override the model with
// .with("model", "...").

local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["image-to-text-" + key]:: value,
        },

    "image-to-text-model":: "gpt-5-mini",
    "image-to-text-max-output":: 4096,

    parameters +:: {
        "image-to-text-cpu-limit": "0.5",
        "image-to-text-cpu-reservation": "0.1",
        "image-to-text-memory-limit": "128M",
        "image-to-text-memory-reservation": "128M",
        "image-to-text-concurrency": 1,
    },

    local logLevel = $.parameters["log-level"],

    "image-to-text" +: {

        local pars = $.parameters,

        local cpuLimit = pars["image-to-text-cpu-limit"],
        local cpuReservation = pars["image-to-text-cpu-reservation"],
        local memoryLimit = pars["image-to-text-memory-limit"],
        local memoryReservation = pars["image-to-text-memory-reservation"],
        local concurrency = pars["image-to-text-concurrency"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "image-to-text-launch-cfg", "launch/image-to-text",
                {
                    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.model.image_to_text.openai.Processor",
                                params: {
                                    id: "image-to-text",
                                    concurrency: concurrency,
                                    model: $["image-to-text-model"],
                                    max_output: $["image-to-text-max-output"],
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
                engine.container("image-to-text")
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
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "image-to-text", [ container ]
            );

            local service =
                engine.internalService("image-to-text", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                cfgVol,
                containerSet,
                service,
            ])

    }

}
