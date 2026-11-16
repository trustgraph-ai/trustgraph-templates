// OntologyRAG extraction module
// Extraction method for OntologyRAG - extracts using ontology definitions
// Mutually exclusive with GraphRAG extraction (both write to graph store)

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local librarian_request = helpers.librarian_request;
local librarian_response = helpers.librarian_response;

{
    "interfaces" +: {
        "extract-ontology": {
            request: request("extract-ontology:{workspace}:{id}"),
            response: response("extract-ontology:{workspace}:{id}"),
        },
    },

    // No configurable parameters for basic KG extraction
    "parameters" +: {
    },

    // Flow-level processors for knowledge extraction
    "flow" +: {
        "kg-extract-ontology:{id}": {
            topics: {
                input: flow("chunk-load:{workspace}:{id}"),
                triples: flow("triples-store:{workspace}:{id}"),
                "entity-contexts": flow("entity-contexts-load:{workspace}:{id}"),
                "prompt-request": request("prompt:{workspace}:{id}"),
                "prompt-response": response("prompt:{workspace}:{id}"),
                "embeddings-request": request("embeddings:{workspace}:{id}"),
                "embeddings-response": response("embeddings:{workspace}:{id}"),
                "ontology-request": request("ontology:{workspace}:{id}"),
                "ontology-response": response("ontology:{workspace}:{id}"),
                request: request("extract-ontology:{workspace}:{id}"),
                response: response("extract-ontology:{workspace}:{id}"),
                "librarian-request": librarian_request,
                "librarian-response": librarian_response,
            },
        },
        "action:{id}" +: {
            topics +: {
                "extract-ontology-request": request("extract-ontology:{workspace}:{id}"),
                "extract-ontology-response": response("extract-ontology:{workspace}:{id}"),
            },
        },
    },

    // No blueprint-level processors needed
    "blueprint" +: {
    }
}

