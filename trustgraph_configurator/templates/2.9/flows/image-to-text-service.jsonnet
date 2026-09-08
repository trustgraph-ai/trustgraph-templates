// Shared image-to-text service module
// Provides image description via a vision-capable model
// Import this module in any flow that requires image description

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by image-to-text service
    "interfaces" +: {
        "image-to-text": request_response_if("image-to-text:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for image-to-text. Only bound when an
    // image-to-text processor is deployed; the entry is inert otherwise.
    "flow" +: {
        "image-to-text:{id}": {
            topics: {
                request: request("image-to-text:{workspace}:{id}"),
                response: response("image-to-text:{workspace}:{id}"),
            },
        },
    },

    "blueprint" +: {
    },
}
