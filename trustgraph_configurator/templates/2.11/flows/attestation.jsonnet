// Attestation management module
// Part of enterprise package

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;
local librarian_request = helpers.librarian_request;
local librarian_response = helpers.librarian_response;

// Import shared services (attestation-engine requires LLM for reasoning
local llm_services = import "llm-services.jsonnet";

// Merge shared services with attestation-specific configuration
llm_services + {

    // External interfaces for attestation operations
    "interfaces" +: {
        "attestation-engine": request_response_if("attestation-engine:{workspace}:{id}"),
    },

    // Flow-level processors
    "flow" +: {

        // Attestation engine orchestrates attested conversations

        "attestation-engine:{id}": {
            topics: {
                request: request("attestation-engine:{workspace}:{id}"),
                response: response("attestation-engine:{workspace}:{id}"),
                "prompt-request": request("prompt-rag:{workspace}:{id}"),
                "prompt-response": response("prompt-rag:{workspace}:{id}"),
                "graph-rag-request": request("graph-rag:{workspace}:{id}"),
                "graph-rag-response": response("graph-rag:{workspace}:{id}"),
                "sparql-request": request("sparql:{workspace}:{id}"),
                "sparql-response": response("sparql:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
                "reranker-request": request("reranker:{workspace}:{id}"),
                "reranker-response": response("reranker:{workspace}:{id}"),
                "triples-request": request("triples:{workspace}:{id}"),
                "triples-response": response("triples:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
                "graph-embeddings-request": request("graph-embeddings:{workspace}:{id}"),
                "graph-embeddings-response": response("graph-embeddings:{workspace}:{id}"),
                explainability: flow("triples-store:{workspace}:{id}"),
            },
        },

    },

    // Blueprint-level processors
    "blueprint" +: {
    },
}
