// Cloze service (HuggingFace) - deploys the cloze processor in its own
// container using the trustgraph-hf image. Provides vector cloze
// generation for text.

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "cloze-cpu-limit": "12.0",
        "cloze-cpu-reservation": "0.5",
        "cloze-memory-limit": "1500M",
        "cloze-memory-reservation": "1500M",
        "cloze-concurrency": 2,
    },

    local logLevel = $.parameters["log-level"],

    "cloze" +: {

        local pars = $.parameters,

        local cpuLimit = pars["cloze-cpu-limit"],
        local cpuReservation = pars["cloze-cpu-reservation"],
        local memoryLimit = pars["cloze-memory-limit"],
        local memoryReservation = pars["cloze-memory-reservation"],
        local concurrency = pars["cloze-concurrency"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "cloze-launch-cfg", "launch/cloze",
                {
                    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.model.cloze.hf.Processor",
                                params: {
                                    id: "cloze",
                                    concurrency: concurrency,
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
                }
            );

            local container =
                engine.container("cloze")
                    .with_image(images.trustgraph_hf)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "cloze", [ container ]
            );

            local service =
                engine.internalService("cloze", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}
