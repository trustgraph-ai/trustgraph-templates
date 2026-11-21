// GraphRAG extraction module
// Extraction method for GraphRAG - extracts definitions and relationships
// Mutually exclusive with OntologyRAG extraction (both write to graph store)

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local librarian_request = helpers.librarian_request;
local librarian_response = helpers.librarian_response;

{
    "interfaces" +: {
        "extract-definitions": {
            request: request("extract-definitions:{workspace}:{id}"),
            response: response("extract-definitions:{workspace}:{id}"),
        },
        "extract-relationships": {
            request: request("extract-relationships:{workspace}:{id}"),
            response: response("extract-relationships:{workspace}:{id}"),
        },
    },

    // No configurable parameters for basic KG extraction
    "parameters" +: {
    },

    // Flow-level processors for knowledge extraction
    "flow" +: {
        // Extracts entity definitions from text chunks
        "kg-extract-definitions:{id}": {
            topics: {
                input: flow("chunk-load:{workspace}:{id}"),
                triples: flow("triples-store:{workspace}:{id}"),
                "entity-contexts": flow("entity-contexts-load:{workspace}:{id}"),
                "prompt-request": request("prompt:{workspace}:{id}"),
                "prompt-response": response("prompt:{workspace}:{id}"),
                request: request("extract-definitions:{workspace}:{id}"),
                response: response("extract-definitions:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },

        // Extracts relationships between entities
        "kg-extract-relationships:{id}": {
            topics: {
                input: flow("chunk-load:{workspace}:{id}"),
                triples: flow("triples-store:{workspace}:{id}"),
                "entity-contexts": flow("entity-contexts-load:{workspace}:{id}"),
                "prompt-request": request("prompt:{workspace}:{id}"),
                "prompt-response": response("prompt:{workspace}:{id}"),
                request: request("extract-relationships:{workspace}:{id}"),
                response: response("extract-relationships:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },
        "action:{id}" +: {
            topics +: {
                "extract-definitions-request": request("extract-definitions:{workspace}:{id}"),
                "extract-definitions-response": response("extract-definitions:{workspace}:{id}"),
                "extract-relationships-request": request("extract-relationships:{workspace}:{id}"),
                "extract-relationships-response": response("extract-relationships:{workspace}:{id}"),
            },
        },
    },

    // No blueprint-level processors needed
    "blueprint" +: {
    }
}