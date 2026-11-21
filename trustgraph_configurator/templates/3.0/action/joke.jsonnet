local images = import "values/images.jsonnet";

{

    parameters +:: {
        "joke-cpu-limit": "0.5",
        "joke-cpu-reservation": "0.1",
        "joke-memory-limit": "256M",
        "joke-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "joke" +: {

        local pars = $.parameters,

        local cpuLimit = pars["joke-cpu-limit"],
        local cpuReservation = pars["joke-cpu-reservation"],
        local memoryLimit = pars["joke-memory-limit"],
        local memoryReservation = pars["joke-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("joke")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "joke-action-service",
            ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "joke", [ container ]
            );

            local service =
                engine.internalService("joke", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
