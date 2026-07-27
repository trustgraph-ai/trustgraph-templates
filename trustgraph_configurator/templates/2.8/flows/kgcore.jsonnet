// Knowledge Graph Core storage module
// Handles persistent storage of knowledge graph data
// Consolidates triples and graph embeddings into permanent storage
// Creates the core knowledge base for long-term use

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;

{
    // No external interfaces - internal storage service
    "interfaces" +: {
    },

    // No configurable parameters for core storage
    "parameters" +: {
    },

    // Flow-level processors for knowledge graph storage
    "flow" +: {
        "kg-store:{id}": {
            topics: {
                "triples-input": flow("triples-store:{workspace}:{id}"),
                "graph-embeddings-input": flow("graph-embeddings-store:{workspace}:{id}"),
            },
        },
    },

    // No blueprint-level processors needed
    "blueprint" +: {
    }
}