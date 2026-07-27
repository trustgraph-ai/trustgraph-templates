// RAG query path: graph- and document-RAG processors plus their
// supporting prompt / LLM interfaces.

local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    parameters +:: {
        "agent-manager-concurrency": 1,
        "graph-rag-concurrency": 1,
        "graph-rag-entity-limit": 50,
        "graph-rag-triple-limit": 30,
        "graph-rag-edge-limit": 30,
        "graph-rag-edge-score-limit": 10,
        "graph-rag-max-subgraph-size": 100,
        "graph-rag-max-path-length": 2,
        "document-rag-concurrency": 1,
        "document-rag-doc-limit": 20,
        // vector | keyword | hybrid; the keyword-index component overrides
        // this to hybrid when included
        "document-rag-retrieval-mode": "vector",
        "nlp-query-concurrency": 1,
        "structured-query-concurrency": 1,
        "structured-diag-concurrency": 1,
        "sparql-query-concurrency": 1,
        "prompt-rag-concurrency": 1,
        "mcp-tool-concurrency": 1,
        "rag-cpu-limit": "0.5",
        "rag-cpu-reservation": "0.1",
        "rag-memory-limit": "640M",
        "rag-memory-reservation": "640M",
        "rag-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],

    "rag" +: {

        local pars = $.parameters,

        local agentManagerConc = pars["agent-manager-concurrency"],
        local graphRagConc = pars["graph-rag-concurrency"],
        local entityLimit = pars["graph-rag-entity-limit"],
        local tripleLimit = pars["graph-rag-triple-limit"],
        local edgeLimit = pars["graph-rag-edge-limit"],
        local edgeScoreLimit = pars["graph-rag-edge-score-limit"],
        local maxSubgraphSize = pars["graph-rag-max-subgraph-size"],
        local maxPathLength = pars["graph-rag-max-path-length"],
        local documentRagConc = pars["document-rag-concurrency"],
        local docLimit = pars["document-rag-doc-limit"],
        local retrievalMode = pars["document-rag-retrieval-mode"],
        local nlpQueryConc = pars["nlp-query-concurrency"],
        local structuredQueryConc = pars["structured-query-concurrency"],
        local structuredDiagConc = pars["structured-diag-concurrency"],
        local sparqlQueryConc = pars["sparql-query-concurrency"],
        local promptRagConc = pars["prompt-rag-concurrency"],
        local mcpToolConc = pars["mcp-tool-concurrency"],
        local cpuLimit = pars["rag-cpu-limit"],
        local cpuReservation = pars["rag-cpu-reservation"],
        local memoryLimit = pars["rag-memory-limit"],
        local memoryReservation = pars["rag-memory-reservation"],
        local replicas = pars["rag-replicas"],

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
                                    concurrency: agentManagerConc,
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
                                    concurrency: documentRagConc,
                                    doc_limit: docLimit,
                                    retrieval_mode: retrievalMode,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: nlpQuery,
                                params: {
                                    id: "nlp-query",
                                    concurrency: nlpQueryConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: structuredQuery,
                                params: {
                                    id: "structured-query",
                                    concurrency: structuredQueryConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: structuredDiag,
                                params: {
                                    id: "structured-diag",
                                    concurrency: structuredDiagConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: sparql,
                                params: {
                                    id: "sparql-query",
                                    concurrency: sparqlQueryConc,
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
                                    concurrency: mcpToolConc,
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
            ).with_replicas(replicas);

            local service =
                engine.internalService("rag", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}
