// Structured store module
// Shared infrastructure for structured data RAG
// Handles row storage, retrieval, and NLP query capabilities

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local flow_if = helpers.flow_if;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

// Import shared services
local llm_services = import "llm-services.jsonnet";
local embeddings_service = import "embeddings-service.jsonnet";

// Merge shared services with structured store configuration
llm_services + embeddings_service + {

    // External interfaces for structured store
    "interfaces" +: {
        // Row storage and querying
        "rows-store": flow_if("rows-store:{workspace}:{id}"),
        "row-embeddings-store": flow_if("row-embeddings-store:{workspace}:{id}"),
        "rows": request_response_if("rows:{workspace}:{id}"),
        "row-embeddings": request_response_if("row-embeddings:{workspace}:{id}"),

        // Query interfaces
        "nlp-query": request_response_if("nlp-query:{workspace}:{id}"),
        "structured-query": request_response_if("structured-query:{workspace}:{id}"),
        "structured-diag": request_response_if("structured-diag:{workspace}:{id}"),
    },

    // Flow-level processors for structured storage and query
    "flow" +: {
        "row-embeddings:{id}": {
            topics: {
                input: flow("rows-store:{workspace}:{id}"),
                output: flow("row-embeddings-store:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
            },
        },
        "rows-write:{id}": {
            topics: {
                input: flow("rows-store:{workspace}:{id}"),
            },
        },
        "row-embeddings-write:{id}": {
            topics: {
                input: flow("row-embeddings-store:{workspace}:{id}"),
            },
        },
        "rows-query:{id}": {
            topics: {
                request: request("rows:{workspace}:{id}"),
                response: response("rows:{workspace}:{id}"),
            },
        },
        "row-embeddings-query:{id}": {
            topics: {
                request: request("row-embeddings:{workspace}:{id}"),
                response: response("row-embeddings:{workspace}:{id}"),
            },
        },
        "nlp-query:{id}": {
            topics: {
                request: request("nlp-query:{workspace}:{id}"),
                response: response("nlp-query:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
            },
        },
        "structured-query:{id}": {
            topics: {
                request: request("structured-query:{workspace}:{id}"),
                response: response("structured-query:{workspace}:{id}"),
                "nlp-query-request": request("nlp-query:{workspace}:{id}"),
                "nlp-query-response": response("nlp-query:{workspace}:{id}"),
                "rows-query-request": request("rows:{workspace}:{id}"),
                "rows-query-response": response("rows:{workspace}:{id}"),
            },
        },
        "structured-diag:{id}": {
            topics: {
                request: request("structured-diag:{workspace}:{id}"),
                response: response("structured-diag:{workspace}:{id}"),
                "prompt-request": request("prompt:{workspace}:{id}"),
                "prompt-response": response("prompt:{workspace}:{id}"),
            },
        },
    },

    "blueprint" +: {
    },
}
