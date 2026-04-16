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
                input: flow("chunk-load:{id}"),
                triples: flow("triples-store:{id}"),
                "entity-contexts": flow("entity-contexts-load:{id}"),
                "prompt-request": request("prompt:{id}"),
                "prompt-response": response("prompt:{id}"),
                "embeddings-request": request("embeddings:{id}"),
                "embeddings-response": response("embeddings:{id}"),
            },
        },
    },

    // No blueprint-level processors needed
    "blueprint" +: {
    }
}

