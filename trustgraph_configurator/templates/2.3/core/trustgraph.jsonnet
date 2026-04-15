local images = import "values/images.jsonnet";

local config_initialiser = import "configuration.jsonnet";
local config  = import "../runtime-config/trustgraph-config.jsonnet";
local control = import "control.jsonnet";
local ingest = import "ingest.jsonnet";
local rag = import "rag.jsonnet";
local api_gateway = import "api-gateway.jsonnet";
local mcp_server = import "mcp-server.jsonnet";
local workbench = import "../ui/workbench-ui.jsonnet";
local ddg = import "mcp/ddg-mcp-server.jsonnet";

{
    parameters +:: {
        "log-level":: "INFO",
    },

    local logLevel = $.parameters["log-level"],

    "document-decoder" +: {

        "cpu-limit":: "0.5",
        "cpu-reservation":: "0.1",
        "memory-limit":: "512M",
        "memory-reservation":: "512M",

        create:: function(engine)

            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];

            local container =
                engine.container("document-decoder")
                    .with_image(images.trustgraph_unstructured)
                    .with_command([
                        "universal-decoder",
                    ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(
                        self["cpu-reservation"],
                        memoryReservation
                    );

            local containerSet = engine.containers(
                "document-decoder", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

} + control + ingest + rag + api_gateway + mcp_server + workbench
  + config_initialiser + config + ddg

