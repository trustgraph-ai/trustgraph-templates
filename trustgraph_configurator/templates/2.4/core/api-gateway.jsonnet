// External HTTP/WebSocket API gateway processor definition.

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "api-gateway-port": 8088,
        "api-gateway-timeout": 600,
        "api-gateway-cpu-limit": "0.5",
        "api-gateway-cpu-reservation": "0.1",
        "api-gateway-memory-limit": "512M",
        "api-gateway-memory-reservation": "512M",
    },

    "api-gateway" +: {

        local pars = $.parameters,

        local logLevel = pars["log-level"],
        local port = pars["api-gateway-port"],
        local timeout = pars["api-gateway-timeout"],
        local cpuLimit = pars["api-gateway-cpu-limit"],
        local cpuReservation = pars["api-gateway-cpu-reservation"],
        local memoryLimit = pars["api-gateway-memory-limit"],
        local memoryReservation = pars["api-gateway-memory-reservation"],

        create:: function(engine)

            local container =
                engine.container("api-gateway")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "api-gateway",
                    ] + $["pub-sub-args"] + [
                        "--timeout",
                        std.toString(timeout),
                        "--port",
                        std.toString(port),
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation)
                    .with_port(port, port, "api");

            local containerSet = engine.containers(
                "api-gateway", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics")
                .with_port(port, port, "api");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
