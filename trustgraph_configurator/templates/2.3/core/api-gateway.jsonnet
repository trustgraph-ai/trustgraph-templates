local images = import "values/images.jsonnet";

{

    "api-gateway" +: {

        port:: 8088,
        timeout:: 600,
        "cpu-limit":: "0.5",
        "cpu-reservation":: "0.1",
        "memory-limit":: "512M",
        "memory-reservation":: "512M",

        local logLevel = $.parameters["log-level"],

        create:: function(engine)

            local port = self.port;
            local timeout = self.timeout;
            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];

            local envSecrets = engine.envSecrets("gateway-secret")
                .with_env_var("GATEWAY_SECRET", "gateway-secret");

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
                    .with_env_var_secrets(envSecrets)
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(self["cpu-reservation"], memoryReservation)
                    .with_port(port, port, "api");

            local containerSet = engine.containers(
                "api-gateway", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics")
                .with_port(port, port, "api");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

}
