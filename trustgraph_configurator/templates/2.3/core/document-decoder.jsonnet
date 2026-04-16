local images = import "values/images.jsonnet";

{

    parameters +:: {
        "document-decoder-cpu-limit": "0.5",
        "document-decoder-cpu-reservation": "0.1",
        "document-decoder-memory-limit": "512M",
        "document-decoder-memory-reservation": "512M",
    },

    local logLevel = $.parameters["log-level"],

    "document-decoder" +: {

        local pars = $.parameters,

        local cpuLimit = pars["document-decoder-cpu-limit"],
        local cpuReservation = pars["document-decoder-cpu-reservation"],
        local memoryLimit = pars["document-decoder-memory-limit"],
        local memoryReservation = pars["document-decoder-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("document-decoder")
                    .with_image(images.trustgraph_unstructured)
                    .with_command([
                        "universal-decoder",
                    ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "document-decoder", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
