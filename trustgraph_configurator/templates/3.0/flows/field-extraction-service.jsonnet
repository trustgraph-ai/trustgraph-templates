// Shared field extraction service module
// Provides field extraction service for text
// Import this module in any flow that requires field extraction aka system 1

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by field extraction service
    "interfaces" +: {
        "field-extraction": request_response_if("field-extraction:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for field extraction
    "flow" +: {
        "field-extraction:{id}": {
            topics: {
                request: request("field-extraction:{workspace}:{id}"),
                response: response("field-extraction:{workspace}:{id}"),
            },
            parameters: {
                model: "tasksource/UltraBERT-150M-clairic-extraction",
                "max-length": "512",
            },
        },
    },

    "blueprint" +: {
    },
}
