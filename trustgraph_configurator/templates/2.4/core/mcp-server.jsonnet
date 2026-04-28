// MCP (Model Context Protocol) server processor — exposes
// TrustGraph tools to MCP-capable clients.

local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    parameters +:: {
        "mcp-server-port": 8000,
        "mcp-server-cpu-limit": "0.5",
        "mcp-server-cpu-reservation": "0.1",
        "mcp-server-memory-limit": "256M",
        "mcp-server-memory-reservation": "256M",
    },

    "mcp-server" +: {

        local pars = $.parameters,

        local port = pars["mcp-server-port"],
        local cpuLimit = pars["mcp-server-cpu-limit"],
        local cpuReservation = pars["mcp-server-cpu-reservation"],
        local memoryLimit = pars["mcp-server-memory-limit"],
        local memoryReservation = pars["mcp-server-memory-reservation"],

        create:: function(engine)

            local envSecrets = engine.envSecrets("mcp-server-secret")
                .with_env_var("MCP_SERVER_SECRET", "mcp-server-secret")
                .with_env_var("GATEWAY_SECRET", "gateway-secret");

            local container =
                engine.container("mcp-server")
                    .with_image(images.trustgraph_mcp)
                    .with_command([
                        "mcp-server",
                        "--port",
                        std.toString(port),
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation)
                    .with_port(port, port, "mcp");

            local containerSet = engine.containers(
                "mcp-server", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(port, port, "mcp");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

}

