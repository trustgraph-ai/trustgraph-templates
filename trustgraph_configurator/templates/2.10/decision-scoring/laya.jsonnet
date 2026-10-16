// Decision scoring (Laya) - deploys the decision scoring processor in
// its own container. Provides fast "system 1" scoring for decisions.

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "decision-scoring-cpu-limit": "3.0",
        "decision-scoring-cpu-reservation": "1.0",
        "decision-scoring-memory-limit": "3G",
        "decision-scoring-memory-reservation": "3G",
        "decision-scoring-concurrency": 1,
    },

    local logLevel = $.parameters["log-level"],

    "decision-scoring" +: {

        local pars = $.parameters,

        local cpuLimit = pars["decision-scoring-cpu-limit"],
        local cpuReservation = pars["decision-scoring-cpu-reservation"],
        local memoryLimit = pars["decision-scoring-memory-limit"],
        local memoryReservation = pars["decision-scoring-memory-reservation"],
        local concurrency = pars["decision-scoring-concurrency"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "decision-scoring-launch-cfg", "launch/decision-scoring",
                {
                    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.model.decision_scoring.laya.Processor",
                                params: {
                                    id: "decision-scoring",
                                    concurrency: concurrency,
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
                }
            );

            local container =
                engine.container("decision-scoring")
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
                "decision-scoring", [ container ]
            );

            local service =
                engine.internalService("decision-scoring", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}
