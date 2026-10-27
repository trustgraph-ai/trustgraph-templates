// Shared embeddings service module
// Provides vector embedding generation for text
// Import this module in any flow that requires embeddings

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by embeddings service
    "interfaces" +: {
        "embeddings": request_response_if("embeddings:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for embeddings
    "flow" +: {
        "embeddings:{id}": {
            topics: {
                request: request("embeddings:{workspace}:{id}"),
                response: response("embeddings:{workspace}:{id}"),
            },
            parameters: {
                model: "{embeddings-model}",
            },
        },
    },

    "blueprint" +: {
    },
}
