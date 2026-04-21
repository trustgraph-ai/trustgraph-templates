// Agent management module
// Provides AI agent orchestration and tool integration
// Manages agent conversations, tool calls, and response coordination
// Supports MCP tools, GraphRAG, and structured queries

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

// Import shared services (agent requires LLM for reasoning, MCP for tools)
local llm_services = import "llm-services.jsonnet";
local mcp_service = import "mcp-service.jsonnet";

// Merge shared services with agent-specific configuration
llm_services + mcp_service + {

    // External interfaces for agent operations
    "interfaces" +: {
        "agent": request_response_if("agent:{workspace}:{id}"),
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
            },
        },
    },

    // Blueprint-level processors for agent-related services
    "blueprint" +: {
    },
}
