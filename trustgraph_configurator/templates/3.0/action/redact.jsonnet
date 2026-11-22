local images = import "values/images.jsonnet";

{

    parameters +:: {
        "redact-cpu-limit": "0.5",
        "redact-cpu-reservation": "0.1",
        "redact-memory-limit": "256M",
        "redact-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "redact" +: {

        local pars = $.parameters,

        local cpuLimit = pars["redact-cpu-limit"],
        local cpuReservation = pars["redact-cpu-reservation"],
        local memoryLimit = pars["redact-memory-limit"],
        local memoryReservation = pars["redact-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("redact")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "redact-action-service",
            ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "redact", [ container ]
            );

            local service =
                engine.internalService("redact", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
