// Shared cloze service module
// Provides cloze generation for text
// Import this module in any flow that requires cloze

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by cloze service
    "interfaces" +: {
        "cloze": request_response_if("cloze:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for cloze
    "flow" +: {
        "cloze:{id}": {
            topics: {
                request: request("cloze:{workspace}:{id}"),
                response: response("cloze:{workspace}:{id}"),
            },
            parameters: {
                model: "distilbert-base-uncased",
            },
        },
    },

    "blueprint" +: {
    },
}
