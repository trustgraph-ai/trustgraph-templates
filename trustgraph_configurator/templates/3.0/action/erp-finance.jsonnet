local images = import "values/images.jsonnet";

{

    parameters +:: {
        "erp-finance-cpu-limit": "0.5",
        "erp-finance-cpu-reservation": "0.1",
        "erp-finance-memory-limit": "256M",
        "erp-finance-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "erp-finance" +: {

        local pars = $.parameters,

        local cpuLimit = pars["erp-finance-cpu-limit"],
        local cpuReservation = pars["erp-finance-cpu-reservation"],
        local memoryLimit = pars["erp-finance-memory-limit"],
        local memoryReservation = pars["erp-finance-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("erp-finance")
                    .with_image(images.trustgraph_erp_data)
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
                "erp-finance", [ container ]
            );

            local service =
                engine.internalService("erp-finance", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
