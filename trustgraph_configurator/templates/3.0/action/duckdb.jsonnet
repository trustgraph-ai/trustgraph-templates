local images = import "values/images.jsonnet";

{

    parameters +:: {
        "duckdb-action-cpu-limit": "0.5",
        "duckdb-action-cpu-reservation": "0.1",
        "duckdb-action-memory-limit": "256M",
        "duckdb-action-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "duckdb-action" +: {

        local pars = $.parameters,

        local cpuLimit = pars["duckdb-action-cpu-limit"],
        local cpuReservation = pars["duckdb-action-cpu-reservation"],
        local memoryLimit = pars["duckdb-action-memory-limit"],
        local memoryReservation = pars["duckdb-action-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("duckdb-action")
                    .with_image("docker.io/trustgraph/trustgraph-duckdb-action-service:0.0.1")
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
                "duckdb-action", [ container ]
            );

            local service =
                engine.internalService("duckdb-action", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
