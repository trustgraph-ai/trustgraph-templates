// Shared reranker service module
// Provides vector reranker generation for text
// Import this module in any flow that requires reranker

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by reranker service
    "interfaces" +: {
        "reranker": request_response_if("reranker:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for reranker
    "flow" +: {
        "reranker:{id}": {
            topics: {
                request: request("reranker:{workspace}:{id}"),
                response: response("reranker:{workspace}:{id}"),
            },
            parameters: {
                model: "{reranker-model}",
            },
        },
    },

    "blueprint" +: {
    },
}
