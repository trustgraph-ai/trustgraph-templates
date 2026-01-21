local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

local config_initialiser = import "configuration.jsonnet";
local config  = import "../runtime-config/trustgraph-config.jsonnet";
local librarian = import "librarian.jsonnet";
local mcp_server = import "mcp-server.jsonnet";
local workbench = import "../ui/workbench-ui.jsonnet";
local graphrag = import "graph-rag.jsonnet";
local documentrag = import "document-rag.jsonnet";
local prompt_template = import "prompt-template.jsonnet";
local agent_manager = import "agent-manager-react.jsonnet";
local structured_data = import "structured-data.jsonnet";
local ddg = import "mcp/ddg-mcp-server.jsonnet";

{

    // Route parameters to appropriate internal objects based on prefix
    // Check more specific prefixes first
    with:: function(k, v)
        if std.startsWith(k, "prompt-rag-") then
            local suffix = std.substr(k, std.length("prompt-rag-"), std.length(k) - std.length("prompt-rag-"));
            self + { "prompt-rag" +: { [suffix]:: v } }
        else if std.startsWith(k, "prompt-") then
            local suffix = std.substr(k, std.length("prompt-"), std.length(k) - std.length("prompt-"));
            self + { prompt +: { [suffix]:: v } }
        else if std.startsWith(k, "text-completion-rag-") then
            local suffix = std.substr(k, std.length("text-completion-rag-"), std.length(k) - std.length("text-completion-rag-"));
            self + { "text-completion-rag" +: { [suffix]:: v } }
        else if std.startsWith(k, "text-completion-") then
            local suffix = std.substr(k, std.length("text-completion-"), std.length(k) - std.length("text-completion-"));
            self + { "text-completion" +: { [suffix]:: v } }
        else if std.startsWith(k, "embeddings-") then
            local suffix = std.substr(k, std.length("embeddings-"), std.length(k) - std.length("embeddings-"));
            self + { embeddings +: { [suffix]:: v } }
        else if std.startsWith(k, "api-gateway-") then
            local suffix = std.substr(k, std.length("api-gateway-"), std.length(k) - std.length("api-gateway-"));
            self + { "api-gateway" +: { [suffix]:: v } }
        else if std.startsWith(k, "chunk-") then
            local suffix = std.substr(k, std.length("chunk-"), std.length(k) - std.length("chunk-"));
            self + { chunker +: { [suffix]:: v } }
        else if std.startsWith(k, "graph-rag-") then
            local suffix = std.substr(k, std.length("graph-rag-"), std.length(k) - std.length("graph-rag-"));
            self + { "graph-rag" +: { [suffix]:: v } }
        else if std.startsWith(k, "kg-extract-definitions-") then
            local suffix = std.substr(k, std.length("kg-extract-definitions-"), std.length(k) - std.length("kg-extract-definitions-"));
            self + { "kg-extract-definitions" +: { [suffix]:: v } }
        else if std.startsWith(k, "kg-extract-relationships-") then
            local suffix = std.substr(k, std.length("kg-extract-relationships-"), std.length(k) - std.length("kg-extract-relationships-"));
            self + { "kg-extract-relationships" +: { [suffix]:: v } }
        else if std.startsWith(k, "kg-extract-agent-") then
            local suffix = std.substr(k, std.length("kg-extract-agent-"), std.length(k) - std.length("kg-extract-agent-"));
            self + { "kg-extract-agent" +: { [suffix]:: v } }
        else if std.startsWith(k, "kg-extract-ontology-") then
            local suffix = std.substr(k, std.length("kg-extract-ontology-"), std.length(k) - std.length("kg-extract-ontology-"));
            self + { "kg-extract-ontology" +: { [suffix]:: v } }
        else
            self + { [k]:: v },

    "log-level":: "DEBUG",

    // Base objects with concurrency defaults (LLM/embeddings components merge into these)
    "text-completion" +: { concurrency:: 1 },
    "text-completion-rag" +: { concurrency:: 1 },
    embeddings +: { concurrency:: 1 },

    "api-gateway" +: {

        port:: 8088,
        timeout:: 600,

        create:: function(engine)

            local port = self.port;
            local timeout = self.timeout;

            local envSecrets = engine.envSecrets("gateway-secret")
                .with_env_var("GATEWAY_SECRET", "gateway-secret");

            local container =
                engine.container("api-gateway")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "api-gateway",
                        "-p",
                        url.pulsar,
                        "--timeout",
                        std.toString(timeout),
                        "--port",
                        std.toString(port),
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "512M")
                    .with_reservations("0.1", "512M")
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

    "chunker" +: {

        size:: 2000,
        overlap:: 50,

        create:: function(engine)

            local size = self.size;
            local overlap = self.overlap;

            local container =
                engine.container("chunker")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "chunker-token",
                        "-p",
                        url.pulsar,
                        "--chunk-size",
                        std.toString(size),
                        "--chunk-overlap",
                        std.toString(overlap),
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "chunker", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "config-svc" +: {
    
        create:: function(engine)

            local container =
                engine.container("config-svc")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "config-svc",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "config-svc", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "pdf-decoder" +: {
    
        create:: function(engine)

            local container =
                engine.container("pdf-decoder")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "pdf-decoder",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "512M")
                    .with_reservations("0.1", "512M");

            local containerSet = engine.containers(
                "pdf-decoder", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "mcp-tool" +: {
    
        create:: function(engine)

            local container =
                engine.container("mcp-tool")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "mcp-tool",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "mcp-tool", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "metering" +: {
    
        create:: function(engine)

            local container =
                engine.container("metering")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "metering",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "metering", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "metering-rag" +: {
    
        create:: function(engine)

            local container =
                engine.container("metering-rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "metering",
                        "-p",
                        url.pulsar,
                        "--id",
                        "metering-rag",
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "metering-rag", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "kg-store" +: {
    
        create:: function(engine)

            local container =
                engine.container("kg-store")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "kg-store",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "kg-store", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                    .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

    "kg-manager" +: {
    
        create:: function(engine)

            local container =
                engine.container("kg-manager")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "kg-manager",
                        "-p",
                        url.pulsar,
                        "--log-level",
                        $["log-level"],
                    ])
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "kg-manager", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                    .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

} + librarian + mcp_server + workbench + graphrag
  + documentrag + prompt_template + agent_manager + structured_data
  + config_initialiser + config
  + ddg

