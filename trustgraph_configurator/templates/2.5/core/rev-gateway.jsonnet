// Reverse gateway processor — ingress front-end that terminates
// external connections and forwards to internal services.

local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    parameters +:: {
        // Invalid default — rev-gateway won't connect to anything it
        // shouldn't until the operator sets a real relay URI.
        "rev-gateway-token": "INVALID_TOKEN",
        "rev-gateway-uri":
            "wss://127.0.0.1/api/v1/relay?token=INVALID_TOKEN",
        "rev-gateway-cpu-limit": "0.5",
        "rev-gateway-cpu-reservation": "0.1",
        "rev-gateway-memory-limit": "256M",
        "rev-gateway-memory-reservation": "256M",
    },

    "rev-gateway" +: {

        local pars = $.parameters,

        local logLevel = pars["log-level"],
        local uri = pars["rev-gateway-uri"],
        local cpuLimit = pars["rev-gateway-cpu-limit"],
        local cpuReservation = pars["rev-gateway-cpu-reservation"],
        local memoryLimit = pars["rev-gateway-memory-limit"],
        local memoryReservation = pars["rev-gateway-memory-reservation"],

        create:: function(engine)

            local envSecrets = engine.envSecrets("rev-gateway-secret")
                .with_env_var("REV_GATEWAY_SECRET", "rev-gateway-secret");

            local container =
                engine.container("rev-gateway")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "rev-gateway",
                    ] + $["pub-sub-args"] + [
                        "--websocket-uri",
                        std.toString(uri),
                        "--log-level",
                        logLevel,
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation)
                    .with_port(8000, 8000, "metrics");

            local containerSet = engine.containers(
                "rev-gateway", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

}

