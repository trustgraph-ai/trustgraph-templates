// Document loading and preprocessing module
// Handles document ingestion, format conversion, and chunking
// Converts PDFs to text and splits documents into processable chunks

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;

{
    // External interfaces for document loading
    "interfaces": {
        "document-load": flow("document-load:{id}"),       // Raw document input stream
        "text-load": flow("text-document-load:{id}"),     // Text document stream
        "embeddings": request_response("embeddings:{class}"), // Embedding service for chunks
    },
    // No configurable parameters for document loading
    "parameters": {
    },
    // Flow-level processors for document preprocessing
    "flow": {
        // PDF decoder converts PDF documents to text
        "pdf-decoder:{id}": {
            input: flow("document-load:{id}"),         // Raw PDF input
            output: flow("text-document-load:{id}"),   // Extracted text output
        },

        // Chunker splits documents into smaller, processable pieces
        "chunker:{id}": {
            input: flow("text-document-load:{id}"),    // Full text documents
            output: flow("chunk-load:{id}"),            // Document chunks for processing
        },
    },
    // Class-level processors for document loading services
    "class": {
        // Embedding service for converting text chunks to vectors
        "embeddings:{class}": {
            request: request("embeddings:{class}"),   // Embedding requests
            response: response("embeddings:{class}"),  // Embedding responses
        },
    }
}