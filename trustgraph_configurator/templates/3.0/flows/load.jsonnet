// Document loading and preprocessing module
// Handles document ingestion, format conversion, and chunking
// Converts PDFs to text and splits documents into processable chunks

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local flow_if = helpers.flow_if;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;
local librarian_request = helpers.librarian_request;
local librarian_response = helpers.librarian_response;

// Import shared services (load requires embeddings for chunk processing)
local embeddings_service = import "embeddings-service.jsonnet";

// Merge shared services with load-specific configuration
embeddings_service + {

    // External interfaces for document loading
    "interfaces" +: {
        "document-load": flow_if("document-load:{workspace}:{id}"),
        "text-load": flow_if("text-document-load:{workspace}:{id}"),
        "document-decode": request_response_if("document-decode:{workspace}:{id}"),
        "chunker": request_response_if("chunker:{workspace}:{id}"),
    },

    // Flow-level processors for document preprocessing
    "flow" +: {
        // PDF decoder converts PDF documents to text
        // Also emits page provenance triples and saves pages via librarian
        "document-decoder:{id}": {
            topics: {
                input: flow("document-load:{workspace}:{id}"),
                output: flow("text-document-load:{workspace}:{id}"),
                request: request("document-decode:{workspace}:{id}"),
                response: response("document-decode:{workspace}:{id}"),
                triples: flow("triples-store:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },

        // Chunker splits documents into smaller, processable pieces
        // Also emits chunk provenance triples and saves chunks via librarian
        "chunker:{id}": {
            topics: {
                input: flow("text-document-load:{workspace}:{id}"),
                output: flow("chunk-load:{workspace}:{id}"),
                triples: flow("triples-store:{workspace}:{id}"),
                request: request("chunker:{workspace}:{id}"),
                response: response("chunker:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
            parameters: {
                "chunk-size": "{chunk-size}",
                "chunk-overlap": "{chunk-overlap}",
            },
        },
    },

    // Blueprint-level processors for document loading services
    "blueprint" +: {
    },
}
