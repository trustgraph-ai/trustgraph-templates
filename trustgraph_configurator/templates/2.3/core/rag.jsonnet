local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    parameters +:: {
        "graph-rag-concurrency": 1,
        "graph-rag-entity-limit": 50,
        "graph-rag-triple-limit": 30,
        "graph-rag-edge-limit": 30,
        "graph-rag-edge-score-limit": 10,
        "graph-rag-max-subgraph-size": 100,
        "graph-rag-max-path-length": 2,
        "document-rag-doc-limit": 20,
        "prompt-rag-concurrency": 1,
        "rag-cpu-limit": "0.5",
        "rag-cpu-reservation": "0.1",
        "rag-memory-limit": "256M",
        "rag-memory-reservation": "256M",
    },

    local logLevel = $.parameters["log-level"],

    "rag" +: {

        local pars = $.parameters,

        local graphRagConc = pars["graph-rag-concurrency"],
        local entityLimit = pars["graph-rag-entity-limit"],
        local tripleLimit = pars["graph-rag-triple-limit"],
        local edgeLimit = pars["graph-rag-edge-limit"],
        local edgeScoreLimit = pars["graph-rag-edge-score-limit"],
        local maxSubgraphSize = pars["graph-rag-max-subgraph-size"],
        local maxPathLength = pars["graph-rag-max-path-length"],
        local docLimit = pars["document-rag-doc-limit"],
        local promptRagConc = pars["prompt-rag-concurrency"],
        local cpuLimit = pars["rag-cpu-limit"],
        local cpuReservation = pars["rag-cpu-reservation"],
        local memoryLimit = pars["rag-memory-limit"],
        local memoryReservation = pars["rag-memory-reservation"],

        local retrieval = "trustgraph.retrieval",
        local agentOrchestrator = "trustgraph.agent.orchestrator.Processor",
        local graphRag = "%s.graph_rag.Processor" % retrieval,
        local documentRag = "%s.document_rag.Processor" % retrieval,
        local nlpQuery = "%s.nlp_query.Processor" % retrieval,
        local structuredQuery = "%s.structured_query.Processor" % retrieval,
        local structuredDiag = "%s.structured_diag.Processor" % retrieval,
        local sparql = "trustgraph.query.sparql.Processor",
        local promptProc = "trustgraph.prompt.template.Processor",
        local mcpTool = "trustgraph.agent.mcp_tool.Service",

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "rag-launch-cfg", "launch/rag",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: agentOrchestrator,
                                params: {
                                    id: "agent-manager",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: graphRag,
                                params: {
                                    id: "graph-rag",
                                    concurrency: graphRagConc,
                                    entity_limit: entityLimit,
                                    triple_limit: tripleLimit,
                                    edge_limit: edgeLimit,
                                    edge_score_limit: edgeScoreLimit,
                                    max_subgraph_size: maxSubgraphSize,
                                    max_path_length: maxPathLength,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: documentRag,
                                params: {
                                    id: "document-rag",
                                    doc_limit: docLimit,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: nlpQuery,
                                params: {
                                    id: "nlp-query",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: structuredQuery,
                                params: {
                                    id: "structured-query",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: structuredDiag,
                                params: {
                                    id: "structured-diag",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: sparql,
                                params: {
                                    id: "sparql-query",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: promptProc,
                                params: {
                                    id: "prompt-rag",
                                    concurrency: promptRagConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: mcpTool,
                                params: {
                                    id: "mcp-tool",
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local container =
                engine.container("rag")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "rag", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}
