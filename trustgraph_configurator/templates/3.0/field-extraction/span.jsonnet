// Field extraction (Span) - deploys the field extraction processor in
// its own container. Provides fast "system 1" span-tagging for field
// extraction using ONNX.

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "field-extraction-cpu-limit": "3.0",
        "field-extraction-cpu-reservation": "1.0",
        "field-extraction-memory-limit": "2G",
        "field-extraction-memory-reservation": "2G",
        "field-extraction-concurrency": 1,
    },

    local logLevel = $.parameters["log-level"],

    "field-extraction" +: {

        local pars = $.parameters,

        local cpuLimit = pars["field-extraction-cpu-limit"],
        local cpuReservation = pars["field-extraction-cpu-reservation"],
        local memoryLimit = pars["field-extraction-memory-limit"],
        local memoryReservation = pars["field-extraction-memory-reservation"],
        local concurrency = pars["field-extraction-concurrency"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "field-extraction-launch-cfg", "launch/field-extraction",
                {
                    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.model.field_extraction.span.Processor",
                                params: {
                                    id: "field-extraction",
                                    concurrency: concurrency,
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
                }
            );

            local container =
                engine.container("field-extraction")
                    .with_image(images.trustgraph_flow)
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
                "field-extraction", [ container ]
            );

            local service =
                engine.internalService("field-extraction", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}
