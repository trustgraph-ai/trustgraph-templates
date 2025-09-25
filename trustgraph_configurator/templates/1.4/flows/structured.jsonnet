// Structured data processing module
// Handles extraction and querying of structured data objects
// Provides natural language to GraphQL query capabilities
// Supports structured data storage and retrieval

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;
local llm_parameters = import "llm-parameters.jsonnet";

{
    // External interfaces for structured data operations
    "interfaces" +: {
        // Supporting services
        "embeddings": request_response("embeddings:{class}"),           // Embedding service
        "prompt": request_response("prompt:{class}"),                   // Prompt processing
        "text-completion": request_response("text-completion:{id}"),  // LLM completion

        // Structured data storage and querying
        "objects-store": flow("objects-store:{id}"),                    // Object storage stream
        "objects": request_response("objects:{class}"),                 // Object query service

        // Query interfaces
        "nlp-query": request_response("nlp-query:{class}"),             // NLP to GraphQL translation
        "structured-query": request_response("structured-query:{class}"), // Structured query execution
        "structured-diag": request_response("structured-diag:{class}"),  // Query diagnostics
    },


    // Parameters that can be configured for this flow
    "parameters" +: llm_parameters,

    // Flow-level processors for structured data extraction
    "flow" +: {
        "kg-extract-objects:{id}": {
            input: flow("chunk-load:{id}"),
            output: flow("objects-store:{id}"),
            "entity-contexts": flow("entity-contexts-load:{id}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
        },
        "objects-write:{id}": {
            input: flow("objects-store:{id}"),
        },
        "text-completion:{id}": {
            request: request("text-completion:{id}"),
            response: response("text-completion:{id}"),
            model: "{llm-model}",
        },
        "text-completion-rag:{id}": {
            request: request("text-completion-rag:{id}"),
            response: response("text-completion-rag:{id}"),
            model: "{llm-rag-model}",
        },
    },
    // Class-level processors for structured data operations
    "class" +: {
        "objects-query:{class}": {
            request: request("objects:{class}"),
            response: response("objects:{class}"),
        },
        "nlp-query:{class}": {
            request: request("nlp-query:{class}"),
            response: response("nlp-query:{class}"),
            "prompt-request": request("prompt-rag:{class}"),
            "prompt-response": response("prompt-rag:{class}"),
        },
        "structured-query:{class}": {
            request: request("structured-query:{class}"),
            response: response("structured-query:{class}"),
            "nlp-query-request": request("nlp-query:{class}"),
            "nlp-query-response": response("nlp-query:{class}"),
            "objects-query-request": request("objects:{class}"),
            "objects-query-response": response("objects:{class}"),
        },
        "structured-diag:{class}": {
            request: request("structured-diag:{class}"),
            response: response("structured-diag:{class}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
        },
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
        },
        "prompt:{class}": {
            request: request("prompt:{class}"),
            response: response("prompt:{class}"),
            "text-completion-request": request("text-completion:{id}"),
            "text-completion-response": response("text-completion:{id}"),
        },
        "prompt-rag:{class}": {
            request: request("prompt-rag:{class}"),
            response: response("prompt-rag:{class}"),
            "text-completion-request": request("text-completion-rag:{id}"),
            "text-completion-response": response("text-completion-rag:{id}"),
        },
        "metering:{class}": {
            input: response("text-completion:{id}"),
        },
        "metering-rag:{class}": {
            input: response("text-completion-rag:{id}"),
        },
    }
}