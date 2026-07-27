// OntologyRAG extraction module
// Extraction method for OntologyRAG - extracts using ontology definitions
// Mutually exclusive with GraphRAG extraction (both write to graph store)

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;

{
    // No external interfaces - this module provides internal extraction
    // services
    "interfaces" +: {
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
            },
        },
    },

    // No blueprint-level processors needed
    "blueprint" +: {
    }
}

