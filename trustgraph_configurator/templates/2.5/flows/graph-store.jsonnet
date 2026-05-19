// Graph store module
// Shared infrastructure for graph-based RAG (used by both GraphRAG and OntologyRAG)
// Handles knowledge graph storage, embeddings, and graph-based question answering

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local flow_if = helpers.flow_if;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;
local librarian_request = helpers.librarian_request;
local librarian_response = helpers.librarian_response;

// Import shared services
local llm_services = import "llm-services.jsonnet";
local embeddings_service = import "embeddings-service.jsonnet";

// Merge shared services with graph store configuration
llm_services + embeddings_service + {

    // External interfaces exposed by the graph store
    "interfaces" +: {
        // Data ingestion interfaces for graph construction
        "entity-contexts-load": flow_if("entity-contexts-load:{workspace}:{id}"),
        "triples-store": flow_if("triples-store:{workspace}:{id}"),
        "graph-embeddings-store": flow_if("graph-embeddings-store:{workspace}:{id}"),

        // Query interfaces for graph-based operations
        "graph-rag": request_response_if("graph-rag:{workspace}:{id}"),
        "triples": request_response_if("triples:{workspace}:{id}"),
        "graph-embeddings": request_response_if("graph-embeddings:{workspace}:{id}"),
        "sparql": request_response_if("sparql:{workspace}:{id}"),
    },

    // Flow-level processors - handle data streams for a specific flow instance
    "flow" +: {
        "graph-embeddings:{id}": {
            topics: {
                input: flow("entity-contexts-load:{workspace}:{id}"),
                output: flow("graph-embeddings-store:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
            },
        },
        "triples-write:{id}": {
            topics: {
                input: flow("triples-store:{workspace}:{id}"),
            },
        },
        "graph-embeddings-write:{id}": {
            topics: {
                input: flow("graph-embeddings-store:{workspace}:{id}"),
            },
        },
        "graph-rag:{id}": {
            topics: {
                request: request("graph-rag:{workspace}:{id}"),
                response: response("graph-rag:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
                "graph-embeddings-request": request("graph-embeddings:{workspace}:{id}"),
                "graph-embeddings-response": response("graph-embeddings:{workspace}:{id}"),
                "triples-request": request("triples:{workspace}:{id}"),
                "triples-response": response("triples:{workspace}:{id}"),
                explainability: flow("triples-store:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },
        "sparql-query:{id}": {
            topics: {
                request: request("sparql:{workspace}:{id}"),
                response: response("sparql:{workspace}:{id}"),
                "triples-request": request("triples:{workspace}:{id}"),
                "triples-response": response("triples:{workspace}:{id}"),
            },
        },
        "triples-query:{id}": {
            topics: {
                request: request("triples:{workspace}:{id}"),
                response: response("triples:{workspace}:{id}"),
            },
        },
        "graph-embeddings-query:{id}": {
            topics: {
                request: request("graph-embeddings:{workspace}:{id}"),
                response: response("graph-embeddings:{workspace}:{id}"),
            },
        },
    },

    // Blueprint-level processors - shared across all flow instances of this blueprint
    "blueprint" +: {
    },
}
