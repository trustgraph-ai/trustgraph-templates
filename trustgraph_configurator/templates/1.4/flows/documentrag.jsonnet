// Document RAG (Retrieval Augmented Generation) module
// Implements document-based RAG using chunk embeddings
// Provides semantic search and context-aware question answering
// Supports MCP (Model Context Protocol) tool integration

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;

{
    // External interfaces for document RAG functionality
    "interfaces": {
        // Document embedding storage and retrieval
        "document-embeddings-store": flow("document-embeddings-store:{id}"), // Embedding storage stream
        "document-rag": request_response("document-rag:{class}"),            // Main document RAG interface
        "document-embeddings": request_response("document-embeddings:{class}"), // Document embedding queries

        // Supporting services
        "embeddings": request_response("embeddings:{class}"),           // General embedding service
        "prompt": request_response("prompt:{class}"),                   // Prompt processing
        "mcp-tool": request_response("mcp-tool:{class}"),               // MCP tool integration
        "text-completion": request_response("text-completion:{class}"),  // LLM text completion
    },
    // Parameters that can be configured for this flow
    "parameters": {
        "llm-model": "llm-model",  // LLM model selection for RAG responses
        "llm-rag-model": "llm-model",  // LLM model for RAG operations
    },
    // Flow-level processors for document embedding and storage
    "flow": {
        "document-embeddings:{id}": {
            input: flow("chunk-load:{id}"),
            output: flow("document-embeddings-store:{id}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
        },
        "de-write:{id}": {
            input: flow("document-embeddings-store:{id}"),
        },
    },
    // Class-level processors for document RAG operations
    "class": {
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
        },
        "document-rag:{class}": {
            request: request("document-rag:{class}"),
            response: response("document-rag:{class}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
            "prompt-request": request("prompt-rag:{class}"),
            "prompt-response": response("prompt-rag:{class}"),
            "document-embeddings-request": request("document-embeddings:{class}"),
            "document-embeddings-response": response("document-embeddings:{class}"),
        },
        "de-query:{class}": {
            request: request("document-embeddings:{class}"),
            response: response("document-embeddings:{class}"),
        },
        "prompt:{class}": {
            request: request("prompt:{class}"),
            response: response("prompt:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
        "prompt-rag:{class}": {
            request: request("prompt-rag:{class}"),
            response: response("prompt-rag:{class}"),
            "text-completion-request": request("text-completion-rag:{class}"),
            "text-completion-response": response("text-completion-rag:{class}"),
        },
        "mcp-tool:{class}": {
            request: request("mcp-tool:{class}"),
            response: response("mcp-tool:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
        "text-completion:{class}": {
            request: request("text-completion:{class}"),
            response: response("text-completion:{class}"),
            model: "{llm-model}",
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
            model: "{llm-rag-model}",
        },
        "metering:{class}": {
            input: response("text-completion:{class}"),
        },
        "metering-rag:{class}": {
            input: response("text-completion-rag:{class}"),
        },
    }
}