// Shared decision scoring service module
// Provides decision scoring service for text
// Import this module in any flow that requires decision scoring aka system 1

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by decision scoring service
    "interfaces" +: {
        "decision-scoring": request_response_if("decision-scoring:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for decision scoring
    "flow" +: {
        "decision-scoring:{id}": {
            topics: {
                request: request("decision-scoring:{workspace}:{id}"),
                response: response("decision-scoring:{workspace}:{id}"),
            },
            parameters: {
                model: "onnx-community/laya-multilingual-ONNX",
            },
        },
    },

    "blueprint" +: {
    },
}
