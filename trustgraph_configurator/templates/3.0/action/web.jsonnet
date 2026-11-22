local images = import "values/images.jsonnet";

{

    parameters +:: {
        "web-action-cpu-limit": "0.5",
        "web-action-cpu-reservation": "0.1",
        "web-action-memory-limit": "256M",
        "web-action-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "web-action" +: {

        local pars = $.parameters,

        local cpuLimit = pars["web-action-cpu-limit"],
        local cpuReservation = pars["web-action-cpu-reservation"],
        local memoryLimit = pars["web-action-memory-limit"],
        local memoryReservation = pars["web-action-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("web-action")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "web-action-service",
            ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "web-action", [ container ]
            );

            local service =
                engine.internalService("web-action", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
