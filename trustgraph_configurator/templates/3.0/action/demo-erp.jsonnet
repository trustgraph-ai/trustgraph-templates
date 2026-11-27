local images = import "values/images.jsonnet";

{

    parameters +:: {
        "demo-erp-cpu-limit": "0.5",
        "demo-erp-cpu-reservation": "0.1",
        "demo-erp-memory-limit": "256M",
        "demo-erp-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "demo-erp" +: {

        local pars = $.parameters,

        local cpuLimit = pars["demo-erp-cpu-limit"],
        local cpuReservation = pars["demo-erp-cpu-reservation"],
        local memoryLimit = pars["demo-erp-memory-limit"],
        local memoryReservation = pars["demo-erp-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("demo-erp")
                    .with_image(images.erp_demo)
                    .with_command([
                        "python",
                        "service.py",
            ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "demo-erp", [ container ]
            );

            local service =
                engine.internalService("demo-erp", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
