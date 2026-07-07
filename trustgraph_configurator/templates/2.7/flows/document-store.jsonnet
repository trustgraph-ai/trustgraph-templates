// Document store module
// Infrastructure for document-based RAG using chunk embeddings
// Handles document embedding storage, retrieval, and question answering

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
local reranker_service = import "reranker-service.jsonnet";
local keyword_index_service = import "keyword-index-service.jsonnet";

// Merge shared services with document store configuration
llm_services + embeddings_service + reranker_service + keyword_index_service + {

    // External interfaces for document store
    "interfaces" +: {
        // Document embedding storage and retrieval
        "document-embeddings-store": flow_if("document-embeddings-store:{workspace}:{id}"),
        "document-rag": request_response_if("document-rag:{workspace}:{id}"),
        "document-embeddings": request_response_if("document-embeddings:{workspace}:{id}"),
    },

    // Flow-level processors for document embedding and storage
    "flow" +: {
        "document-embeddings:{id}": {
            topics: {
                input: flow("chunk-load:{workspace}:{id}"),
                output: flow("document-embeddings-store:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
            },
        },
        "doc-embeddings-write:{id}": {
            topics: {
                input: flow("document-embeddings-store:{workspace}:{id}"),
            },
        },
        "document-rag:{id}": {
            topics: {
                request: request("document-rag:{workspace}:{id}"),
                response: response("document-rag:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
                "document-embeddings-request": request("document-embeddings:{workspace}:{id}"),
                "document-embeddings-response": response("document-embeddings:{workspace}:{id}"),
                "reranker-request": request("reranker:{workspace}:{id}"),
                "reranker-response": response("reranker:{workspace}:{id}"),
                "keyword-index-request": request("keyword-index:{workspace}:{id}"),
                "keyword-index-response": response("keyword-index:{workspace}:{id}"),
                explainability: flow("triples-store:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },
        "doc-embeddings-query:{id}": {
            topics: {
                request: request("document-embeddings:{workspace}:{id}"),
                response: response("document-embeddings:{workspace}:{id}"),
            },
        },
    },

    // Blueprint-level processors for document RAG operations
    "blueprint" +: {
    },
}
