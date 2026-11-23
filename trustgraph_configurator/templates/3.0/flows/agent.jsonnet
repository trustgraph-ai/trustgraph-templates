// Agent management module
// Provides AI agent orchestration and tool integration
// Manages agent conversations, tool calls, and response coordination
// Supports MCP tools, GraphRAG, and structured queries

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;
local librarian_request = helpers.librarian_request;
local librarian_response = helpers.librarian_response;

// Import shared services (agent requires LLM for reasoning, MCP for tools)
local llm_services = import "llm-services.jsonnet";
local mcp_service = import "mcp-service.jsonnet";

// Merge shared services with agent-specific configuration
llm_services + mcp_service + {

    // External interfaces for agent operations
    "interfaces" +: {
        "agent": request_response_if("agent:{workspace}:{id}"),
        "orchestrator": request_response_if("orchestrator:{workspace}:{id}"),
        "query-formulation": request_response_if("query-formulation:{workspace}:{id}"),
        "planner": request_response_if("planner:{workspace}:{id}"),
        "verification": request_response_if("verification:{workspace}:{id}"),
        "policy": request_response_if("policy:{workspace}:{id}"),
        "action": request_response_if("action:{workspace}:{id}"),
    },

    // Flow-level processors for agent management
    "flow" +: {
        // Agent manager orchestrates agent conversations and tool usage
        "agent-manager:{id}": {
            topics: {
                request: request("agent:{workspace}:{id}"),
                next: request("agent:{workspace}:{id}"),
                response: response("agent:{workspace}:{id}"),
                "text-completion-request": request("text-completion:{workspace}:{id}"),
                "text-completion-response": response("text-completion:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
                "mcp-tool-request": request("mcp-tool:{workspace}:{id}"),
                "mcp-tool-response": response("mcp-tool:{workspace}:{id}"),
                "graph-rag-request": request("graph-rag:{workspace}:{id}"),
                "graph-rag-response": response("graph-rag:{workspace}:{id}"),
                "structured-query-request": request("structured-query:{workspace}:{id}"),
                "structured-query-response": response("structured-query:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
                "row-embeddings-query-request": request("row-embeddings:{workspace}:{id}"),
                "row-embeddings-query-response": response("row-embeddings:{workspace}:{id}"),
                explainability: flow("triples-store:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },

        // Orchestrator coordinates execution engine steps
        "orchestrator:{id}": {
            topics: {
                request: request("orchestrator:{workspace}:{id}"),
                response: response("orchestrator:{workspace}:{id}"),
                next: request("orchestrator:{workspace}:{id}"),
                "planner-request": request("planner:{workspace}:{id}"),
                "planner-response": response("planner:{workspace}:{id}"),
                "policy-request": request("policy:{workspace}:{id}"),
                "policy-response": response("policy:{workspace}:{id}"),
                "action-request": request("action:{workspace}:{id}"),
                "action-response": response("action:{workspace}:{id}"),
                "verification-request": request("verification:{workspace}:{id}"),
                "verification-response": response("verification:{workspace}:{id}"),
            },
        },

        // Query formulation transforms queries using prompt service
        "query-formulation:{id}": {
            topics: {
                request: request("query-formulation:{workspace}:{id}"),
                response: response("query-formulation:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
            },
        },

        // Planner decomposes goals into execution DAGs
        "planner:{id}": {
            topics: {
                request: request("planner:{workspace}:{id}"),
                response: response("planner:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
            },
        },

        // Verification validates execution plan outputs
        "verification:{id}": {
            topics: {
                request: request("verification:{workspace}:{id}"),
                response: response("verification:{workspace}:{id}"),
            },
        },

        // Action worker executes individual plan steps
        "action:{id}": {
            topics: {
                request: request("action:{workspace}:{id}"),
                response: response("action:{workspace}:{id}"),
                "graph-rag-request": request("graph-rag:{workspace}:{id}"),
                "graph-rag-response": response("graph-rag:{workspace}:{id}"),
                "text-completion-request": request("text-completion:{workspace}:{id}"),
                "text-completion-response": response("text-completion:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
                "concept-extraction-request": request("concept-extraction:{workspace}:{id}"),
                "concept-extraction-response": response("concept-extraction:{workspace}:{id}"),
                "knowledge-retrieval-request": request("knowledge-retrieval:{workspace}:{id}"),
                "knowledge-retrieval-response": response("knowledge-retrieval:{workspace}:{id}"),
                "graph-embeddings-request": request("graph-embeddings:{workspace}:{id}"),
                "graph-embeddings-response": response("graph-embeddings:{workspace}:{id}"),
                "triples-request": request("triples:{workspace}:{id}"),
                "triples-response": response("triples:{workspace}:{id}"),
                "query-formulation-request": request("query-formulation:{workspace}:{id}"),
                "query-formulation-response": response("query-formulation:{workspace}:{id}"),
                "document-rag-request": request("document-rag:{workspace}:{id}"),
                "document-rag-response": response("document-rag:{workspace}:{id}"),
                "document-embeddings-request": request("document-embeddings:{workspace}:{id}"),
                "document-embeddings-response": response("document-embeddings:{workspace}:{id}"),
                "reranker-request": request("reranker:{workspace}:{id}"),
                "reranker-response": response("reranker:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
                "cloze-request": request("cloze:{workspace}:{id}"),
                "cloze-response": response("cloze:{workspace}:{id}"),
                "decision-scoring-request": request("decision-scoring:{workspace}:{id}"),
                "decision-scoring-response": response("decision-scoring:{workspace}:{id}"),
                "field-extraction-request": request("field-extraction:{workspace}:{id}"),
                "field-extraction-response": response("field-extraction:{workspace}:{id}"),
                "sparql-request": request("sparql:{workspace}:{id}"),
                "sparql-response": response("sparql:{workspace}:{id}"),
                "document-decode-request": request("document-decode:{workspace}:{id}"),
                "document-decode-response": response("document-decode:{workspace}:{id}"),
                "chunker-request": request("chunker:{workspace}:{id}"),
                "chunker-response": response("chunker:{workspace}:{id}"),
            },
        },

        // Policy engine enforces execution policies
        "policy:{id}": {
            topics: {
                request: request("policy:{workspace}:{id}"),
                response: response("policy:{workspace}:{id}"),
            },
        },

    },

    // Blueprint-level processors for agent-related services
    "blueprint" +: {
    },
}

