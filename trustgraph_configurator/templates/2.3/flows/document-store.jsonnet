// Document store module
// Infrastructure for document-based RAG using chunk embeddings
// Handles document embedding storage, retrieval, and question answering

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local flow_if = helpers.flow_if;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

// Import shared services
local llm_services = import "llm-services.jsonnet";
local embeddings_service = import "embeddings-service.jsonnet";

// Merge shared services with document store configuration
llm_services + embeddings_service + {

    // External interfaces for document store
    "interfaces" +: {
        // Document embedding storage and retrieval
        "document-embeddings-store": flow_if("document-embeddings-store:{id}"),
        "document-rag": request_response_if("document-rag:{id}"),
        "document-embeddings": request_response_if("document-embeddings:{id}"),
    },

    // Flow-level processors for document embedding and storage
    "flow" +: {
        "document-embeddings:{id}": {
            topics: {
                input: flow("chunk-load:{id}"),
                output: flow("document-embeddings-store:{id}"),
                "embeddings-request": request("embeddings:{id}"),
                "embeddings-response": response("embeddings:{id}"),
            },
        },
        "doc-embeddings-write:{id}": {
            topics: {
                input: flow("document-embeddings-store:{id}"),
            },
        },
        "document-rag:{id}": {
            topics: {
                request: request("document-rag:{id}"),
                response: response("document-rag:{id}"),
                "embeddings-request": request("embeddings:{id}"),
                "embeddings-response": response("embeddings:{id}"),
                "prompt-request": request("prompt-rag:{id}"),
                "prompt-response": response("prompt-rag:{id}"),
                "document-embeddings-request": request("document-embeddings:{id}"),
                "document-embeddings-response": response("document-embeddings:{id}"),
                explainability: flow("triples-store:{id}"),
            },
        },
        "doc-embeddings-query:{id}": {
            topics: {
                request: request("document-embeddings:{id}"),
                response: response("document-embeddings:{id}"),
            },
        },
    },

    // Blueprint-level processors for document RAG operations
    "blueprint" +: {
    },
}
